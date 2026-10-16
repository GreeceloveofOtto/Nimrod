"""Minimal positive-key alternatives for physical gate contacts."""
def minimal(options):
 result=set()
 for candidate in sorted(options,key=lambda m:(m.bit_count(),m)):
  if not any(old&candidate==old for old in result):result.add(candidate)
 return frozenset(result)
def combine(bits,requirements,cache=None):
 if cache is not None and bits in cache:return cache[bits]
 original=bits;result=frozenset([0])
 while bits:
  bit=bits&-bits;row=requirements[bit.bit_length()-1];options=[row]if isinstance(row,int)else row
  result=minimal(a|b for a in result for b in options);bits-=bit
 if cache is not None:cache[original]=result
 return result
def condense(ea,eb,masks,labels,renumber,requirements):
 result={};cache={}
 for a,b,bits in zip(ea,eb,masks):
  ca=renumber[int(labels[a])];cb=renumber[int(labels[b])]
  if ca==cb:continue
  key=(ca,cb);result[key]=minimal(set(result.get(key,()))|set(combine(bits,requirements,cache)))
 return result
