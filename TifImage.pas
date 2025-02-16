unit TifImage;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Description:	Reader and writer for TIFF images                             //
// Version:	0.1                                                           //
// Date:	16-FEB-2025                                                   //
// License:     MIT                                                           //
// Target:	Win64, Free Pascal, Delphi                                    //
// Copyright:	(c) 2025 Xelitan.com.                                         //
//		All rights reserved.                                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

interface

uses Classes, Graphics, SysUtils, Types, Dialogs;

const LIB_TIF = 'libtiff.dll';

type
  tsize_t = NativeInt;
  toff_t = Int64;
  thandle_t = Pointer;
  TIFF = Pointer;
  PTIFF = ^TIFF;

  // TIFF tag data types
  TTiffTag = (
    TIFF_NOTYPE = 0,
    TIFF_BYTE    = 1,
    TIFF_ASCII   = 2,
    TIFF_SHORT   = 3,
    TIFF_LONG    = 4,
    TIFF_RATIONAL= 5,
    TIFF_SBYTE   = 6,
    TIFF_UNDEFINED=7,
    TIFF_SSHORT  = 8,
    TIFF_SLONG   = 9,
    TIFF_SRATIONAL=10,
    TIFF_FLOAT   = 11,
    TIFF_DOUBLE  = 12,
    TIFF_IFD     = 13
  );
  // TIFF Compression Types
  TTifCompression = (
    COMPRESSION_NONE   = 1,
    COMPRESSION_RLE    = 2,           //won't save
    COMPRESSION_CCITT3 = 3,
    COMPRESSION_CCITT4 = 4,
    COMPRESSION_LZW    = 5,
    COMPRESSION_JPEG   = 7,
    COMPRESSION_ADOBE_DEFLATE = 8,
    COMPRESSION_NEXT        = 32766,  //won't save
    COMPRESSION_PACKBITS    = 32773,
    COMPRESSION_THUNDERSCAN = 32809,  //won't save
    COMPRESSION_DEFLATE     = 32946,
    COMPRESSION_JBIG        = 34661,  //won't save
    COMPRESSION_JPEG_2000   = 34712,  //won't save
    COMPRESSION_LZMA2       = 34925,  //rare
    COMPRESSION_Zstandard   = 50000,  //rare
    COMPRESSION_WebP        = 50001,
    COMPRESSION_JPEG_XL     = 50002   //won't save
  );
  //constants
const
  TIFFTAG_IMAGEWIDTH    = 256;
  TIFFTAG_IMAGELENGTH   = 257;
  TIFFTAG_BITSPERSAMPLE = 258;
  TIFFTAG_COMPRESSION   = 259;
  TIFFTAG_PHOTOMETRIC   = 262;
  TIFFTAG_SAMPLESPERPIXEL = 277;
  TIFFTAG_PLANARCONFIG    = 284;
  TIFFTAG_ORIENTATION     = 274;
  TIFFTAG_STRIPOFFSETS    = 273;
  TIFFTAG_ROWSPERSTRIP    = 278;
  TIFFTAG_STRIPBYTECOUNTS = 279;
  TIFFTAG_XRESOLUTION     = 282;
  TIFFTAG_YRESOLUTION     = 283;
  TIFFTAG_RESOLUTIONUNIT  = 296;
  TIFFTAG_EXTRASAMPLES    = 338;

  // Photometric Interpretations
  PHOTOMETRIC_WHITEBLACK    = 0;
  PHOTOMETRIC_BLACKWHITE    = 1;
  PHOTOMETRIC_RGB           = 2;
  PHOTOMETRIC_PALETTE       = 3;
  PHOTOMETRIC_CMYK          = 5;
  EXTRASAMPLE_ASSOCALPHA    = 1;
  // Planar Configuration
  PLANARCONFIG_CONTIG       = 1;
  // Orientation
  ORIENTATION_TOPLEFT       = 1;

  // Seek origins
  SEEK_SET = 0;
  SEEK_CUR = 1;
  SEEK_END = 2;

  function TIFFClientOpen(name: PAnsiChar; mode: PAnsiChar; clientdata: thandle_t; eadproc: Pointer; writeproc: Pointer; seekproc: Pointer;
    closeproc: Pointer; sizeproc: Pointer; mapproc: Pointer; unmapproc: Pointer): PTIFF; cdecl; external LIB_TIF;
  function TIFFGetField(tif: PTIFF; tag: Cardinal; outptr: Pointer): Integer; cdecl; external LIB_TIF;
  function TIFFReadRGBAImage(tif: PTIFF; width: Cardinal; height: Cardinal; raster: Pointer; stop: Integer): Integer; cdecl; external LIB_TIF;
  function _TIFFmalloc(size: tsize_t): Pointer; cdecl; external LIB_TIF;
  procedure _TIFFfree(ptr: Pointer); cdecl; external LIB_TIF;
  procedure TIFFClose(tif: PTIFF); cdecl; external LIB_TIF;
  function TIFFOpen(name: PAnsiChar; mode: PAnsiChar): PTIFF; cdecl; external LIB_TIF;
  function TIFFSetField4(tif: PTIFF; tag: Cardinal; v1,v2,v3,v4: UInt16): Integer; cdecl; external LIB_TIF name 'TIFFSetField';
  function TIFFSetField(tif: PTIFF; tag: Cardinal; value: UInt32): Integer; cdecl; external LIB_TIF;
  function TIFFWriteScanline(tif: PTIFF; buf: Pointer; row: UInt32; sample: Word): Integer; cdecl; external LIB_TIF;

type
  PTIFFMemoryStream = ^TTIFFMemoryStream;
  TTIFFMemoryStream = record
    Stream: TMemoryStream;
  end;

  { TTifImage }
type
  TTifImage = class(TGraphic)
  private
    FBmp: TBitmap;
    FCompression: TTifCompression;
    procedure DecodeFromStream(Str: TStream);
    procedure EncodeToStream(Str: TStream);
  protected
    procedure Draw(ACanvas: TCanvas; const Rect: TRect); override;
  //    function GetEmpty: Boolean; virtual; abstract;
    function GetHeight: Integer; override;
    function GetTransparent: Boolean; override;
    function GetWidth: Integer; override;
    procedure SetHeight(Value: Integer); override;
    procedure SetTransparent(Value: Boolean); override;
    procedure SetWidth(Value: Integer);override;
  public
    procedure SetCompression(Value: TTifCompression);
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

// TIFF I/O Callbacks
function ReadFun(fd: thandle_t; buf: Pointer; size: tsize_t): tsize_t; cdecl;
var Stream: PTIFFMemoryStream;
begin
  Stream := PTIFFMemoryStream(fd);

  if size > 0 then begin
    Result := Stream.Stream.Read(buf^, size);
  end
  else
    Result := 0;
end;

function WriteFun(fd: thandle_t; buf: Pointer; size: tsize_t): tsize_t; cdecl;
var
  Handle: PTIFFMemoryStream;
begin
  Handle := PTIFFMemoryStream(fd);
  Result := Handle.Stream.Write(buf^, size);
end;

function SeekFun(fd: thandle_t; offset: toff_t; whence: integer): toff_t; cdecl;
var ms: pTIFFMemoryStream;
begin
  ms := pTIFFMemoryStream(fd);
  case whence of
    SEEK_SET: ms.stream.Position := offset;
    SEEK_CUR: ms.stream.Position := ms.stream.Position + offset;
    SEEK_END: ms.stream.Position := ms.stream.Size + offset;
  else
    ms.stream.Position := offset;
  end;
  Result := ms.stream.position;
end;

function CloseFun(fd: thandle_t): Integer; cdecl;
begin
  Result := 0;
end;

function SizeFun(fd: thandle_t): toff_t; cdecl;
var Str: pTIFFMemoryStream;
begin
  Str := pTIFFMemoryStream(fd);
  Result :=  Str.Stream.Size;
end;

{ TTifImage }

procedure TTifImage.DecodeFromStream(Str: TStream);
var AStr: TTIFFMemoryStream;
    tif: PTIFF;
    AWidth, AHeight: UInt32;
    raster: Pointer;
    x,y: Integer;
    SrcPtr: PByte;
    orient: UInt32;
    P: PByteArray;
begin
  AStr.Stream := TMemoryStream.Create;
  AStr.Stream.CopyFrom(Str, Str.Size);
  aStr.Stream.Position := 0;

  tif := TIFFClientOpen('', 'r', @AStr, @ReadFun, @WriteFun, @SeekFun, @CloseFun, @SizeFun, nil, nil);
  if not Assigned(tif) then Exit;

  try
    if TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, @AWidth) <> 1 then Exit;
    if TIFFGetField(tif, TIFFTAG_IMAGELENGTH, @AHeight) <> 1 then Exit;
    TIFFGetField(tif, TIFFTAG_ORIENTATION, @orient);

    raster := _TIFFmalloc(AWidth * AHeight * SizeOf(UInt32));
    if not Assigned(raster) then Exit;

    try
      if TIFFReadRGBAImage(tif, AWidth, AHeight, raster, 0) <> 1 then Exit;

      FBmp.SetSize(AWidth, AHeight);
      SrcPtr := PByte(raster);

      if Orient = 0 then
          for y:=AHeight-1 downto 0 do begin
            P := FBmp.Scanline[y];

            for x:=0 to AWidth-1 do begin
              P[4*x+2] := SrcPtr^; Inc(SrcPtr);
              P[4*x+1] := SrcPtr^; Inc(SrcPtr);
              P[4*x  ] := SrcPtr^; Inc(SrcPtr);
              P[4*x+3] := SrcPtr^; Inc(SrcPtr); //alfa
            end;
          end
      else
          for y:=0 to AHeight-1 do begin
            P := FBmp.Scanline[y];

            for x:=0 to AWidth-1 do begin
              P[4*x+2] := SrcPtr^; Inc(SrcPtr);
              P[4*x+1] := SrcPtr^; Inc(SrcPtr);
              P[4*x  ] := SrcPtr^; Inc(SrcPtr);
              P[4*x+3] := SrcPtr^; Inc(SrcPtr); //alfa
            end;
          end;
    finally
      _TIFFfree(raster);
    end;
  finally
    TIFFClose(tif);
  end;
end;

procedure TTifImage.EncodeToStream(Str: TStream);
var Tiff: PTIFF;
    AStr: TTIFFMemoryStream;
    P: PByteArray;
    Buffer: array of Byte;
    x,y: Integer;
    Dst: PByte;
begin
  AStr.Stream := TMemoryStream.Create;

  tiff := TIFFClientOpen('', 'w4', thandle_t(@AStr), @ReadFun, @WriteFun, @SeekFun, @CloseFun, @SizeFun, nil, nil);

  if not Assigned(Tiff) then
    raise Exception.Create('Failed to create TIFF file');

  try
    // Set required TIFF tags
    TIFFSetField(Tiff, TIFFTAG_IMAGEWIDTH, FBmp.Width);
    TIFFSetField(Tiff, TIFFTAG_IMAGELENGTH, FBmp.Height);
    TIFFSetField4(Tiff, TIFFTAG_BITSPERSAMPLE, 8,8,8,8);
    TIFFSetField(Tiff, TIFFTAG_SAMPLESPERPIXEL, 4);
    TIFFSetField(Tiff, TIFFTAG_PHOTOMETRIC, ord(PHOTOMETRIC_RGB));
    TIFFSetField(Tiff, TIFFTAG_PLANARCONFIG, ord(PLANARCONFIG_CONTIG));
    TIFFSetField(Tiff, TIFFTAG_COMPRESSION, ord(FCompression));
    TIFFSetField(Tiff, TIFFTAG_ORIENTATION, ord(ORIENTATION_TOPLEFT));
    TIFFSetField(Tiff, TIFFTAG_ROWSPERSTRIP, FBmp.Height);
    TIFFSetField(Tiff, TIFFTAG_XRESOLUTION, 72);
    TIFFSetField(Tiff, TIFFTAG_YRESOLUTION, 72);
    TIFFSetField(Tiff, TIFFTAG_RESOLUTIONUNIT, 2);

    SetLength(Buffer, FBmp.Width * 4);
    for y := 0 to FBmp.Height - 1 do
    begin
      P := FBmp.ScanLine[y];
      Dst := @Buffer[0];

      for x := 0 to FBmp.Width - 1 do
      begin
        Dst^ := P[4*x+2];
        Inc(Dst);
        Dst^ := P[4*x+1];
        Inc(Dst);
        Dst^ := P[4*x  ];
        Inc(Dst);
        Dst^ := 255-P[4*x+3]; //alpha
        Inc(Dst);
      end;
      if TIFFWriteScanline(Tiff, @Buffer[0], y, 0) < 0 then
        raise Exception.CreateFmt('Error writing row %d', [y]);
    end;
  finally
    TIFFClose(Tiff);

    AStr.Stream.Position := 0;
    Str.CopyFrom(AStr.Stream, AStr.Stream.Size);
    AStr.Stream.Free;
  end;
end;

procedure TTifImage.Draw(ACanvas: TCanvas; const Rect: TRect);
begin
  ACanvas.StretchDraw(Rect, FBmp);
end;

function TTifImage.GetHeight: Integer;
begin
  Result := FBmp.Height;
end;

function TTifImage.GetTransparent: Boolean;
begin
  Result := False;
end;

function TTifImage.GetWidth: Integer;
begin
  Result := FBmp.Width;
end;

procedure TTifImage.SetHeight(Value: Integer);
begin
  FBmp.Height := Value;
end;

procedure TTifImage.SetTransparent(Value: Boolean);
begin
  //
end;

procedure TTifImage.SetWidth(Value: Integer);
begin
  FBmp.Width := Value;
end;

procedure TTifImage.SetCompression(Value: TTifCompression);
begin
  FCompression := Value;
end;

procedure TTifImage.Assign(Source: TPersistent);
var Src: TGraphic;
begin
  if source is tgraphic then begin
    Src := Source as TGraphic;
    FBmp.SetSize(Src.Width, Src.Height);
    FBmp.Canvas.Draw(0,0, Src);
  end;
end;

procedure TTifImage.LoadFromStream(Stream: TStream);
begin
  DecodeFromStream(Stream);
end;

procedure TTifImage.SaveToStream(Stream: TStream);
begin
  EncodeToStream(Stream);
end;

constructor TTifImage.Create;
begin
  inherited Create;

  FBmp := TBitmap.Create;
  FBmp.PixelFormat := pf32bit;
  FBmp.SetSize(1,1);
  FCompression := COMPRESSION_DEFLATE;
end;

destructor TTifImage.Destroy;
begin
  FBmp.Free;
  inherited Destroy;
end;

initialization
  TPicture.RegisterFileFormat('tif','Tiff Image', TTifImage);
  TPicture.RegisterFileFormat('tiff','Tiff Image', TTifImage);

finalization
  TPicture.UnregisterGraphicClass(TTifImage);
  TPicture.UnregisterGraphicClass(TTifImage);

end.
