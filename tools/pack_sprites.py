#!/usr/bin/env python3
"""Pack image-generated art; never synthesize game art.

Examples:
    python tools/pack_sprites.py sheet raw.png idle.png --grid-cols 8 --grid-rows 8 --row 0 --frames 6 --fit 460,300
    python tools/pack_sprites.py image raw.png door.png --crop 0,0,512,768 --size 320,420

Sprite scales are shared across an atlas, using a reference frame (default first
idle pose). Every pose retains that scale and is anchored at its bottom center.
Magenta-key source images are the output of the image-generation tool.
"""

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image


def numbers(value, count):
    items = tuple(int(item) for item in value.split(","))
    if len(items) != count:
        raise argparse.ArgumentTypeError(f"Expected {count} comma-separated integers")
    return items


def chromakey(image):
    """Remove solid #FF00FF and its antialiased magenta fringe."""
    pixels = np.array(image.convert("RGBA"), dtype=np.float32)
    red, green, blue = pixels[..., 0], pixels[..., 1], pixels[..., 2]
    dominance = np.minimum(red, blue) - green
    key = (red >= 35) & (blue >= 35) & (green <= 145) & (dominance >= 30)
    pixels[key, 3] = 0
    pixels[key, :3] = 0
    # Keep natural brown/red/gold art while removing thin, partially keyed edges.
    fringe = (~key) & (red >= 12) & (blue >= 12) & (dominance > 12)
    pixels[fringe, 3] *= np.clip((30 - dominance[fringe]) / 18, 0, 1)
    pixels[fringe, 0] = np.minimum(pixels[fringe, 0], pixels[fringe, 1] + 8)
    pixels[fringe, 2] = np.minimum(pixels[fringe, 2], pixels[fringe, 1] + 8)
    return Image.fromarray(pixels.astype(np.uint8), "RGBA")


def cell_box(image, cols, rows, column, row):
    if not (0 <= column < cols and 0 <= row < rows):
        raise ValueError("Grid cell lies outside atlas")
    width, height = image.size
    return (round(column * width / cols), round(row * height / rows),
            round((column + 1) * width / cols), round((row + 1) * height / rows))


def foreground(image):
    bounds = image.getchannel("A").point(lambda alpha: 255 if alpha > 12 else 0).getbbox()
    if bounds is None:
        raise ValueError("Frame is empty after chromakey; check source grid/crop")
    return image.crop(bounds), bounds


def save_image(image, output):
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, optimize=True)
    print(json.dumps({"output": str(output), "size": list(image.size), "mode": image.mode}))


def crop_source(source, crop):
    if not crop:
        return source
    x, y, width, height = crop
    if width <= 0 or height <= 0 or x < 0 or y < 0 or x + width > source.width or y + height > source.height:
        raise ValueError("Crop must lie within source image")
    return source.crop((x, y, x + width, y + height))


def automatic_boxes(source, gap):
    occupied = np.asarray(source.getchannel("A")) > 32
    columns = np.any(occupied, axis=0)
    spans, start, empty = [], None, 0
    for x, exists in enumerate(columns):
        if exists:
            if start is None:
                start = x
            empty = 0
        elif start is not None:
            empty += 1
            if empty >= gap:
                end = x - empty + 1
                if end - start >= 8:
                    spans.append((start, 0, end, source.height))
                start, empty = None, 0
    if start is not None:
        spans.append((start, 0, len(columns) - empty, source.height))
    return spans


def component_poses(source, count, rows=1):
    """Crop complete connected figures and retain detached weapon fragments.
    All returned pixels are copied from the generated source; no poses are drawn.
    """
    from scipy import ndimage
    pixels=np.asarray(source)
    labels,total=ndimage.label(pixels[:,:,3]>12,structure=np.ones((3,3),dtype=bool))
    areas=np.bincount(labels.ravel());areas[0]=0
    ordered=np.argsort(areas)[::-1];ordered=ordered[areas[ordered]>0]
    if len(ordered)<count:raise ValueError(f"Only {len(ordered)} components; expected {count}")
    bodies=list(ordered[:count]);parts=[[int(i)] for i in bodies]
    if min(areas[bodies])<max(areas[bodies])*.1:raise ValueError("Joined figures or a missing body; regenerate source")
    objects=ndimage.find_objects(labels)
    def bounds(index):
        y,x=objects[index-1];return [x.start,y.start,x.stop,y.stop]
    body_bounds=[bounds(i) for i in bodies]
    for item in ordered[count:]:
        left,top,right,bottom=bounds(item)
        def distance(box):return max(box[0]-right,left-box[2],0)**2+max(box[1]-bottom,top-box[3],0)**2
        nearest=min(range(count),key=lambda i:distance(body_bounds[i]));parts[nearest].append(int(item))
    poses=[]
    for group in parts:
        boxes=[bounds(i) for i in group];left=min(b[0] for b in boxes);top=min(b[1] for b in boxes);right=max(b[2] for b in boxes);bottom=max(b[3] for b in boxes)
        selected=pixels[top:bottom,left:right].copy();selected[~np.isin(labels[top:bottom,left:right],group)]=0
        poses.append(((min(rows-1,int(((top+bottom)/2)/source.height*rows)),(left+right)/2),Image.fromarray(selected,"RGBA")))
    return [p for _,p in sorted(poses,key=lambda entry:entry[0])]


def pack_sheet(args):
    source = chromakey(crop_source(Image.open(args.source).convert("RGBA"), args.crop))
    if args.frames < 1:
        raise ValueError("Frame count must be positive")
    if not args.auto_cells and not args.boxes and not args.components and args.column + args.frames > args.grid_cols:
        raise ValueError("Frame count must fit one atlas row")
    poses = None
    if args.components:
        poses = component_poses(source, args.frames)
        boxes = [(0, 0, pose.width, pose.height) for pose in poses]
    elif args.boxes:
        rects = json.loads(args.boxes)
        boxes = [(x, y, x + width, y + height) for x, y, width, height in rects]
    elif args.auto_cells:
        boxes = automatic_boxes(source, args.cell_gap)
        if len(boxes) != args.frames:
            raise ValueError(f"Detected {len(boxes)} figures, expected {args.frames}; use --boxes for explicit crops")
    else:
        boxes = [cell_box(source, args.grid_cols, args.grid_rows, args.column + index, args.row)
                 for index in range(args.frames)]
    if len(boxes) != args.frames:
        raise ValueError("Box count must equal --frames")
    reference_box = boxes[0] if args.auto_cells or args.boxes or args.components else cell_box(
        source, args.grid_cols, args.grid_rows, args.reference_column, args.reference_row)
    reference, _ = foreground(poses[0] if poses else source.crop(reference_box))
    fit_width, fit_height = args.fit
    scale = args.scale if args.scale else min(fit_width / reference.width, fit_height / reference.height)
    if scale <= 0:
        raise ValueError("Scale must be positive")
    scale_x, scale_y = args.scale_xy if args.scale_xy else (scale, scale)
    if scale_x <= 0 or scale_y <= 0:
        raise ValueError("Both scaling factors must be positive")
    frame_size = (args.frame_width, args.frame_height)
    anchor_x, anchor_y = args.anchor
    if not (0 <= anchor_x <= args.frame_width and 0 <= anchor_y <= args.frame_height):
        raise ValueError("Anchor must lie inside output frame")
    sheet = Image.new("RGBA", (args.frames * args.frame_width, args.frame_height), (0, 0, 0, 0))
    frame_info = []
    if args.reverse:
        boxes.reverse()
        if poses:
            poses.reverse()
    for index, box in enumerate(boxes):
        crop = poses[index] if poses else source.crop(box)
        if index in args.flip_frames:
            crop = crop.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        pose, source_bounds = foreground(crop)
        resized = pose.resize((max(1, round(pose.width * scale_x)), max(1, round(pose.height * scale_y))),
                              Image.Resampling.LANCZOS)
        if args.alignment == "left-center":
            x, y = anchor_x, round(anchor_y - resized.height / 2)
        elif args.alignment == "center":
            x, y = round(anchor_x - resized.width / 2), round(anchor_y - resized.height / 2)
        else:
            x, y = round(anchor_x - resized.width / 2), anchor_y - resized.height
        if x < 0 or y < 0 or x + resized.width > args.frame_width or y + resized.height > args.frame_height:
            raise ValueError(f"Frame {index + 1} clips at shared scale {scale:.4f}; decrease --scale/--fit")
        frame = Image.new("RGBA", frame_size, (0, 0, 0, 0))
        frame.alpha_composite(resized, (x, y))
        sheet.alpha_composite(frame, (index * args.frame_width, 0))
        frame_info.append({"frame": index + 1, "source_bounds": list(source_bounds),
                           "packed_bounds": [x, y, x + resized.width, y + resized.height]})
    save_image(sheet, args.output)
    apply_storage_policy(args, sheet, True)
    print(json.dumps({"shared_scale": scale, "anchor": list(args.anchor), "frames": frame_info}))


def pack_image(args):
    source = crop_source(Image.open(args.source).convert("RGBA"), args.crop)
    if not args.opaque:
        source = chromakey(source)
    if args.trim:
        source, _ = foreground(source)
    if args.size:
        source = source.resize(args.size, Image.Resampling.LANCZOS)
    if args.opaque:
        source.putalpha(255)
    if args.tile_x:
        # Blend a narrow pair of mirrored EXISTING image edge strips into
        # matching borders; no shapes, noise or procedural terrain are drawn.
        band = min(args.tile_x, source.width // 2)
        if band < 1:
            raise ValueError("Tile edge band must be positive")
        pixels = np.asarray(source, dtype=np.float32).copy()
        left = pixels[:, :band].copy()
        right = pixels[:, -band:][:, ::-1].copy()
        weights = np.linspace(1, 0, band, dtype=np.float32)[None, :, None] if band > 1 else 1
        shared = (left + right) / 2
        pixels[:, :band] = left * (1 - weights) + shared * weights
        pixels[:, -band:] = (right * (1 - weights) + shared * weights)[:, ::-1]
        pixels = np.rint(pixels).astype(np.uint8)
        # Exact equality at the wrap seam, including alpha.
        pixels[:, -1] = pixels[:, 0]
        source = Image.fromarray(pixels, "RGBA")
    if not args.opaque:
        source = chromakey(source)  # Remove 1-alpha magenta resampling fringe.
    save_image(source, args.output)
    apply_storage_policy(args, source, False)


def apply_storage_policy(args, image, is_sheet):
    """Automatically normalize new runtime art; preserve canonical geometry sidecar."""
    from downscale_assets import ROOT, choose_scale, encode, rewrite_paths
    import shutil
    output=Path(args.output).resolve()
    try:relative=output.relative_to(ROOT/'assets')
    except ValueError:return  # Staging/reference art stays untouched.
    policy_path=ROOT/'data/image_policy.json'
    if not policy_path.exists() or getattr(args,'canonical_only',False):return
    policy=json.loads(policy_path.read_text());folder='assets/'+relative.parts[0];mode=policy.get(folder,{}).get('mode','keep')
    if mode=='keep':return
    backup=ROOT/'archive/pack_source'/relative;backup.parent.mkdir(parents=True,exist_ok=True)
    if backup.exists() and backup.read_bytes()!=output.read_bytes():
        import hashlib
        previous=ROOT/'archive/pack_source_history'/relative.parent/(relative.stem+'_'+hashlib.sha256(backup.read_bytes()).hexdigest()[:16]+relative.suffix)
        previous.parent.mkdir(parents=True,exist_ok=True)
        if not previous.exists():shutil.copy2(backup,previous)
    shutil.copy2(output,backup)
    spec={}
    if is_sheet:
        limits=json.loads((ROOT/'data/density_limits.json').read_text());limit=limits.get(args.density_class,2);w,h=args.frame_width,args.frame_height
        frames=[image.crop((i*w,0,(i+1)*w,h)) for i in range(args.frames)];boxes=[f.getchannel('A').getbbox() for f in frames];x=max(0,min(b[0] for b in boxes)-2);y=max(0,min(b[1] for b in boxes)-2);right=min(w,max(b[2] for b in boxes)+2);bottom=min(h,max(b[3] for b in boxes)+2);cw,ch=right-x,bottom-y
        packed=Image.new('RGBA',(cw*args.frames,ch))
        for i,f in enumerate(frames):packed.paste(f.crop((x,y,right,bottom)),(i*cw,0))
        scale,sw,sh,quality,density=choose_scale(packed,cw,ch,args.frames,args.visual_scale,limit);image=Image.new('RGBA',(sw*args.frames,sh))
        for i in range(args.frames):image.paste(packed.crop((i*cw,0,(i+1)*cw,ch)).resize((sw,sh),Image.Resampling.LANCZOS),(i*sw,0))
        spec={'frame_width':w,'frame_height':h,'anchor_px':list(args.anchor),'frames':args.frames,'columns':args.frames,'rows':1,'trim':{'x':x,'y':y,'w':cw,'h':ch},'storage_trim':{'x':x*sw/cw,'y':y*sh/ch,'w':sw,'h':sh},'storage_scale':[sw/cw,sh/ch],'stored_columns':args.frames,'frame_map':list(range(args.frames)),'stored_frame_size':[round(w*sw/cw),round(h*sh/ch)],'stored_anchor_px':[args.anchor[0]*sw/cw,args.anchor[1]*sh/ch],'image_size':list(image.size),'ssim':quality,'effective_density':density}
    if is_sheet:
        from stage11_repack import pad_sheet,pad_spec
        image=pad_sheet(image,sw,sh,args.frames)
        pad_spec(spec,sw,sh,args.frames)
    target=output.with_suffix('.webp')
    if is_sheet:
        from stage10_optimize_density import encoded
        content,metrics=encoded(image);target.write_bytes(content)
    else:
        exception=policy.get('exceptions',{}).get(str(target.relative_to(ROOT)),{})
        if exception.get('mode')=='lossless':
            image.save(target,'WEBP',lossless=True,method=6,exact=True);metrics={'mode':'lossless','quality':100,'alpha_mae':0.,'rgb_mae':0.,'bbox_same':True}
        else:metrics=encode(image,target,policy.get(folder,{}).get('quality',86))
    spec['encoding']=metrics
    if output!=target:output.unlink();rewrite_paths({'assets/'+str(relative):str(target.relative_to(ROOT))})
    target.with_suffix('.storage.json').write_text(json.dumps(spec,indent=2)+'\n')
    if is_sheet:
        registry_path=ROOT/'data/sprite_trims.json';registry=json.loads(registry_path.read_text());key='res://'+str(target.relative_to(ROOT));registry[key]=spec;registry_path.write_text(json.dumps(registry,indent=2)+'\n')
        for manifest in target.parent.glob('*manifest.json'):
            data=json.loads(manifest.read_text())
            for clip in data.get('clips',[]):
                if Path(clip['sheet']).stem==output.stem:clip.update(spec);clip['sheet']=str(Path(clip['sheet']).with_suffix('.webp'))
            manifest.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
        quality_path=ROOT/'data/storage_quality.json'
        rows=json.loads(quality_path.read_text()) if quality_path.exists() else []
        record={'path':key,'source':str(target.relative_to(ROOT)),'source_archive':str(backup.relative_to(ROOT/'archive')),'source_canonical':True,'source_bytes':backup.stat().st_size,'output_bytes':target.stat().st_size,'storage_scale':spec['storage_scale'],'stored_frames':args.frames,'frames':args.frames,'density':density,'ssim':quality,**metrics}
        rows=[row for row in rows if row['path']!=key]+[record]
        quality_path.write_text(json.dumps(rows,indent=2)+'\n')
    else:
        quality_path=ROOT/'data/image_encoding_quality.json'
        rows=json.loads(quality_path.read_text()) if quality_path.exists() else []
        key=str(target.relative_to(ROOT))
        record={'path':key,'source':str(backup.relative_to(ROOT/'archive/pack_source')),'source_archive':str(backup.relative_to(ROOT/'archive')),'before':backup.stat().st_size,'after':target.stat().st_size,'ssim':1.0,**metrics}
        rows=[row for row in rows if row['path']!=key]+[record]
        quality_path.write_text(json.dumps(rows,indent=2)+'\n')
    print(json.dumps({'policy_output':str(target),'metadata':str(target.with_suffix('.storage.json'))}))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    sheet = commands.add_parser("sheet", help="Chromakey, align and pack a generated atlas row")
    sheet.add_argument("source")
    sheet.add_argument("output")
    sheet.add_argument("--grid-cols", type=int, default=1)
    sheet.add_argument("--grid-rows", type=int, default=1)
    sheet.add_argument("--row", type=int, default=0, help="Zero-based atlas row")
    sheet.add_argument("--column", type=int, default=0, help="Zero-based first column")
    sheet.add_argument("--frames", type=int, required=True)
    sheet.add_argument("--crop", type=lambda value: numbers(value, 4), help="Crop atlas strip first: x,y,width,height")
    sheet.add_argument("--auto-cells", action="store_true", help="Split strip by transparent column gaps")
    sheet.add_argument("--components", action="store_true", help="Extract disconnected original painted figures, even with x-overlap")
    sheet.add_argument("--cell-gap", type=int, default=4, help="Minimum transparent gap for --auto-cells")
    sheet.add_argument("--boxes", help='Explicit crop rectangles after --crop: "[[x,y,w,h],...]"')
    sheet.add_argument("--reverse", action="store_true", help="Reverse generated poses, e.g. lowering into rising")
    sheet.add_argument("--flip-frames", type=lambda value: [int(index) for index in value.split(",")], default=[],
                       help="Mirror specified zero-based source frame indices to correct reference orientation")
    sheet.add_argument("--frame-width", type=int, default=640)
    sheet.add_argument("--frame-height", type=int, default=640)
    sheet.add_argument("--anchor", type=lambda value: numbers(value, 2), default=(320, 600))
    sheet.add_argument("--alignment", choices=("bottom-center", "left-center", "center"), default="bottom-center")
    sheet.add_argument("--fit", type=lambda value: numbers(value, 2), default=(460, 300))
    sheet.add_argument("--reference-row", type=int, default=0)
    sheet.add_argument("--reference-column", type=int, default=0)
    sheet.add_argument("--scale", type=float, help="Override atlas-wide scale; same value for every clip")
    sheet.add_argument("--scale-xy", type=lambda value: tuple(float(v) for v in value.split(",")),
                       help="Effects only: existing painted pixels scaled to the desired hitbox aspect (x,y)")
    sheet.add_argument("--visual-scale",type=float,default=.30)
    sheet.add_argument("--density-class",choices=("player","player_stage11","npc","enemy","large_enemy","fx"),default="enemy")
    sheet.add_argument("--canonical-only",action="store_true",help="Only for archived reference/staging sheets")
    sheet.set_defaults(run=pack_sheet)
    single = commands.add_parser("image", help="Crop/resize generated map and prop art")
    single.add_argument("source")
    single.add_argument("output")
    single.add_argument("--crop", type=lambda value: numbers(value, 4), help="x,y,width,height")
    single.add_argument("--size", type=lambda value: numbers(value, 2), help="Output width,height")
    single.add_argument("--trim", action="store_true", help="Remove empty margins before resizing")
    single.add_argument("--opaque", action="store_true", help="Preserve background and force fully opaque alpha")
    single.add_argument("--tile-x", nargs="?", type=int, const=32, default=0,
                        help="Blend existing edge strips for exact seamless left/right RGBA borders (default band32px)")
    single.set_defaults(run=pack_image)
    args = parser.parse_args()
    try:
        args.run(args)
    except (OSError, ValueError) as error:
        parser.exit(1, f"ERROR: {error}\n")


if __name__ == "__main__":
    main()
