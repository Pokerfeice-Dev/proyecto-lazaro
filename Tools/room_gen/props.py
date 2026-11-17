import numpy as np, json
from PIL import Image
from scipy import ndimage
import os
R = os.environ.get('LAZARO_ROOT') or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..') + os.sep
ATLAS=Image.open(R+'Art/Tileset/Area 3/Cursed Land/CursedLand_Atlas.png').convert('RGBA')
A=np.array(ATLAS)[...,3]>0
LAB,N=ndimage.label(ndimage.binary_dilation(A,iterations=2))
def prop_tiles(seed_x,seed_y,w,h):
    """Tiles ocupados por el objeto cuyo componente domina el recuadro (x,y,w,h)."""
    sub=LAB[seed_y*16:(seed_y+h)*16, seed_x*16:(seed_x+w)*16]
    sa=A[seed_y*16:(seed_y+h)*16, seed_x*16:(seed_x+w)*16]
    ids=sub[sa]
    ids=ids[ids>0]
    if len(ids)==0: return []
    best=np.bincount(ids).argmax()
    m=(LAB==best)&A
    ys,xs=np.nonzero(m)
    tiles=sorted({(int(x//16),int(y//16)) for x,y in zip(xs,ys)})
    return tiles
def prop_block(name,x,y,w,h):
    t=prop_tiles(x,y,w,h)
    x0=min(a for a,b in t); y0=min(b for a,b in t)
    return {'name':name,'tiles':[(a,b) for a,b in t],'origin':(x0,y0),
            'w':max(a for a,b in t)-x0+1,'h':max(b for a,b in t)-y0+1}
# catálogo curado: nombre -> recuadro donde buscar el objeto
CAT={
 'calaveras':(0,40,3,2),'calaveras2':(0,42,3,2),'hueso':(7,40,3,3),
 'huesito_a':(12,41,2,2),'huesito_b':(14,41,2,2),'huesito_c':(16,41,2,2),
 'piedras_bajas_a':(32,41,4,2),'piedras_bajas_b':(39,41,4,2),
 'esqueleto_a':(45,42,4,3),'esqueleto_b':(45,45,4,3),
 'circulo_piedras':(0,43,7,7),'circulo_piedras_b':(6,43,8,7),
 'arco_piedra_a':(34,43,6,4),'arco_piedra_b':(39,43,6,4),
 'roca_grande_a':(23,47,4,4),'roca_grande_b':(5,49,4,4),
 'hierba_ojos_a':(34,49,6,6),'hierba_ojos_b':(40,49,6,6),'hierba_ojos_fina':(46,50,3,5),
 'ojo_gigante_a':(16,35,9,8),'ojo_gigante_b':(25,35,9,8),
 'arbol_azul':(7,54,7,7),'planta_carnivora':(14,54,6,7),
 'roca_marron_a':(27,55,3,3),'roca_marron_b':(30,55,3,3),'coral':(33,55,3,3),
 'cuerno':(36,55,4,3),'espinas':(39,55,3,3),'huevo':(42,55,3,3),'planta_ojos':(47,55,2,3),
 'cerebro_a':(18,61,5,4),'cerebro_b':(28,61,4,4),
 'flor_rosa_a':(39,65,5,5),'flor_rosa_b':(44,65,5,5),
 'huevos_gemelos':(36,61,5,5),
 'roca_negra':(9,61,5,5),
 'panal_a':(21,74,4,4),'panal_chico':(25,77,2,2),
}
if __name__=='__main__':
    from PIL import ImageDraw
    S=3
    items=[]
    for k,b in CAT.items():
        p=prop_block(k,*b)
        im=Image.new('RGBA',(p['w']*16,p['h']*16),(0,0,0,0))
        for (a,b2) in p['tiles']:
            t=ATLAS.crop((a*16,b2*16,a*16+16,b2*16+16))
            im.alpha_composite(t,((a-p['origin'][0])*16,(b2-p['origin'][1])*16))
        items.append((k,p,im.resize((im.width*S,im.height*S),Image.NEAREST)))
    cols=6; cw=9*16*S+8
    rows=[items[i:i+cols] for i in range(0,len(items),cols)]
    rh=[max(i[2].height for i in r)+20 for r in rows]
    sheet=Image.new('RGBA',(cols*cw,sum(rh)),(40,36,50,255)); d=ImageDraw.Draw(sheet); y=0
    for r,h in zip(rows,rh):
        for i,(k,p,im) in enumerate(r):
            sheet.alpha_composite(im,(i*cw,y+18)); d.text((i*cw+2,y+2),f"{k} {p['w']}x{p['h']}",fill=(255,255,0,255))
        y+=h
    sheet.save('catalogo.png'); print(sheet.size)
