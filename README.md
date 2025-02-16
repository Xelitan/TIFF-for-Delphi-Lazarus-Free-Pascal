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

## This unit uses LibTIFF:
https://gitlab.com/libtiff/libtiff
License:
https://gitlab.com/libtiff/libtiff/-/blob/master/LICENSE.md
