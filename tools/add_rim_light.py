#!/usr/bin/env python3
"""Allowed NPC postprocess: brighten a 5px inner alpha edge facing top-left.

Copies original RGB/alpha; no silhouette, background or character art is drawn.
"""
import argparse
from pathlib import Path
import numpy as np
from PIL import Image


def add_rim_light(image, width=5, strength=0.40):
    pixels=np.array(image.convert('RGBA'),dtype=np.float32)
    alpha=pixels[...,3]>12
    lit=np.zeros(alpha.shape,dtype=bool)
    for offset in range(1,width+1):
        left=np.zeros_like(alpha);left[:,offset:]=alpha[:,:-offset]
        above=np.zeros_like(alpha);above[offset:,:]=alpha[:-offset,:]
        lit |= alpha & (~left | ~above)
    # Interior band only; preserve the exact source alpha and anchor.
    color=np.array([255,232,196],dtype=np.float32)
    pixels[lit,:3]=pixels[lit,:3]*(1-strength)+color*strength
    return Image.fromarray(pixels.astype(np.uint8),'RGBA')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path);parser.add_argument('output',type=Path)
    parser.add_argument('--width',type=int,default=5);parser.add_argument('--strength',type=float,default=0.40)
    args=parser.parse_args()
    args.output.parent.mkdir(parents=True,exist_ok=True)
    add_rim_light(Image.open(args.source),args.width,args.strength).save(args.output)

if __name__=='__main__':main()
