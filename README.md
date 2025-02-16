# TIFF-for-Delphi-Lazarus-Free-Pascal
TIFF image reading/writing for Delphi, Lazarus, Free Pascal

## Uwage examples
```
  Image1.Picture.LoadFromFile('test.tif');
```

```
var t: TTifImage;
begin
 Image1.Picture.LoadFromFile('test.bmp');

 t := TTifImage.Create;
 t.Assign(Image1.Picture.Bitmap);
 t.SetCompression(COMPRESSION_LZW);
 t.SaveToFile('out.tif');
 t.Free; 
```

## This library can save to these TIFF formats:

- uncompressed
- CCITT3
- CCITT4
- LZW   
- JPEG  
- ADOBE DEFLATE
- PACKBITS
- DEFLATE (aka ZIP)
- LZMA2     //rare
- Zstandard //rare
- WebP      //rare

## This unit uses LibTIFF:
https://gitlab.com/libtiff/libtiff
License:
https://gitlab.com/libtiff/libtiff/-/blob/master/LICENSE.md

## Linux (Debian, Ubuntu, Mint)

1) apt install apt-file libtiff-dev
2) apt-file search libtiff.so
It will list you how your libtiff.so files are named *exactly* and where they are
3) Open TifImage.pas and edit "const LIB_TIF"
4) Change the value of that const. Enter filename (excluding path) found in step 2
5) Compile and run
