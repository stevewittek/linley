#!/bin/sh
# Original geometric artwork, authored for Linley; no external media or music.
set -eu
cd "$(dirname "$0")/.."
for spec in 'DemoSun FFA34D FF596D' 'DemoBlue 65AEE5 FFE8CF' 'DemoCoral FF7986 432E68' 'DemoPaper F5DFB1 367BB7'; do
  set -- $spec
  mkdir -p "Linley/Resources/Assets.xcassets/$1.imageset"
  ffmpeg -loglevel error -y -f lavfi -i "color=c=0x$2:s=600x800" -vf "drawbox=x=80:y=100:w=440:h=250:color=0x$3:t=fill,drawbox=x=200:y=240:w=240:h=440:color=white@0.7:t=fill,drawbox=x=60:y=560:w=340:h=90:color=0x$3:t=fill" -frames:v 1 -threads 1 "Linley/Resources/Assets.xcassets/$1.imageset/$1.png"
  printf '{"images":[{"filename":"%s.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}\n' "$1" > "Linley/Resources/Assets.xcassets/$1.imageset/Contents.json"
done
ffmpeg -loglevel error -y -f lavfi -i 'color=c=0x65AEE5:s=480x640:r=24:d=4' -vf "drawbox=x=60:y=100:w=360:h=220:color=0xFF7986:t=fill,rotate=0.1*sin(t*2):fillcolor=0xFFA34D" -c:v libx264 -pix_fmt yuv420p -movflags +faststart Linley/Resources/DemoMotion.mp4
