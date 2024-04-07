{$MODE OBJFPC}
{$MACRO ON}{$H+}
{$COPERATORS ON}

library imageManager;

{$calling cdecl}

uses
   sysutils, FPimage
   ,FPReadPNG, FPReadJPEG, FPReadBMP, FPReadGif, FPReadTGA, FPReadTiff, FPReadPSD
   ,FPWritePNG, FPWriteJPEG, FPWriteBMP, FPWriteTGA, FPwriteTiff
   ,FPCanvas, FPImgCanv
   ,zstream
;

{$DEFINE VERSION_MAYOR := 1}
{$DEFINE VERSION_MINOR := 0}
{$DEFINE VERSION_ALPHA := 0}
{$DEFINE VERSION_BUILD := 1}

{$DEFINE RETURN := RESULT :=}

type
   Tpixel = record
      red, green, blue, alpha : byte;
   end;

   TImageData = record
      width, height : DWORD;
      data : array of Tpixel;
   end;

   PTImageData = ^TImageData;

function mkPixel(r,g,b:byte; a:byte=255):Tpixel;
begin
   RESULT.red   := r;
   RESULT.green := g;
   RESULT.blue  := b;
   RESULT.alpha := a;
end;

function mkColor(r,g,b:byte; a:byte=255):TFPColor;
begin
   RESULT.red   := r << 8;
   RESULT.green := g << 8;
   RESULT.blue  := b << 8;
   RESULT.alpha := a << 8;
end;

function convertPixel(pixel : TFPColor): TPixel;
begin
   RETURN mkPixel(
      pixel.red   >> 8,
      pixel.green >> 8,
      pixel.blue  >> 8,
      pixel.alpha >> 8
   );
end;

function deconvertPixel(pixel : TPixel): TFPColor;
begin
   RETURN mkColor(
      pixel.red,
      pixel.green,
      pixel.blue,
      pixel.alpha
   );
end;

var
   readerPNG, readerJPEG, readerBMP, readerGIF, readerTGA, readerTIFF, readerPSD
   : TFPCustomImageReader;
   writerPNG, writerJPEG, writerBMP, writerTGA, writerTIFF
   : TFPCustomImageWriter;

function init(): boolean; EXPORT;
begin
   try
      readerPNG  := TFPReaderPNG.create();
      readerJPEG := TFPReaderJPEG.create();
      readerBMP  := TFPReaderBMP.create();
      readerGIF  := TFPReaderGIF.create();
      readerTGA  := TFPReaderTarga.create();
      readerTIFF := TFPReaderTIFF.create();
      readerPSD  := TFPReaderPSD.create();
      writerPNG  := TFPWriterPNG.create();
      writerJPEG := TFPWriterJPEG.create();
      writerBMP  := TFPWriterBMP.create();
      writerTGA  := TFPWriterTarga.create();
      writerTIFF := TFPWriterTIFF.create();
   except
      exit(false);
   end;
   exit(true);
end;

function done(): boolean; EXPORT;
begin
   try
      readerPNG.free();
      readerJPEG.free();
      readerBMP.free();
      readerGIF.free();
      readerTGA.free();
      readerTIFF.free();
      readerPSD.free();
      writerPNG.free();
      writerJPEG.free();
      writerBMP.free();
      writerTGA.free();
      writerTIFF.free();
   except
      exit(false);
   end;
   exit(true);
end;

function getReader(fname:string): TFPCustomImageReader;
var ext : String;
begin
   ext := ExtractFileExt(fname);
   ext := ext.ToUpper();
   case ext of
      '.JPG','.JPE','.JPEG' : EXIT( readerJPEG );
      '.BMP'  : EXIT( readerBMP );
      '.GIF'  : EXIT( readerGIF );
      '.TGA'  : EXIT( readerTGA );
      '.TIFF' : EXIT( readerTIFF );
      '.PSD'  : EXIT( readerPSD );
      '.PNG'  : EXIT( readerPNG );
   end;
   RETURN readerPNG;
end;

function getWriter(fname:string): TFPCustomImageWriter;
var ext : String;
begin
   ext := ExtractFileExt(fname);
   ext := ext.ToUpper();
   case ext of
      '.JPG','.JPE','.JPEG' : EXIT( writerJPEG );
      '.BMP'  : EXIT( writerBMP );
      '.TGA'  : EXIT( writerTGA );
      '.TIFF' : EXIT( writerTIFF );
      '.PNG'  : EXIT( writerPNG );
   end;
   RETURN writerPNG;
end;

function tryLoadImage(image : TFPCustomImage; fname:string): boolean;
begin
   try image.loadFromFile(fname, getReader(fname)); EXIT(true);
   except end;
   try image.loadFromFile(fname, readerPNG); EXIT(true);
   except end;
   try image.loadFromFile(fname, readerJPEG); EXIT(true);
   except end;
   try image.loadFromFile(fname, readerBMP); EXIT(true);
   except end;
   try image.loadFromFile(fname, readerGIF); EXIT(true);
   except end;
   try image.loadFromFile(fname, readerTGA); EXIT(true);
   except end;
   try image.loadFromFile(fname, readerTIFF); EXIT(true);
   except end;
   try image.loadFromFile(fname, readerPSD); EXIT(true);
   except end;
   try
      image.loadFromFile(fname, TFPReaderPNG.create());
      EXIT(true);
   except
   end;
   EXIT(false);
end;

function trySaveImage(image : TFPCustomImage; fname:string): boolean;
begin
   try image.SaveToFile(fname, getWriter(fname)); EXIT(true);
   except end;
   try image.SaveToFile(fname, writerPNG); EXIT(true);
   except end;
   try image.SaveToFile(fname, writerJPEG); EXIT(true);
   except end;
   try image.SaveToFile(fname, writerBMP); EXIT(true);
   except end;
   try image.SaveToFile(fname, writerTGA); EXIT(true);
   except end;
   try image.SaveToFile(fname, writerTIFF); EXIT(true);
   except end;
   try
      image.SaveToFile(fname, TFPWriterPNG.create());
      EXIT(true);
   except
   end;
   EXIT(false);
end;

function FileExists(fname:string):boolean;
var f : file;
begin
   try
      assign(f, fname);
      reset(f, 1);
      close(f);
      RETURN True;
   except
      RETURN False;
   end;
end;

function reconstruirString(fname : string):string;
var res : string;
    i : longint;
begin
   res := '';
   i := 0;
   for i := 1 to $ffff do begin
    if (ord(fname[i]) <> 0) then
       res := res + fname[i]
    else
       break;
   end;
   RETURN res;
end;

function loadImage(fname : String; imagen:PTImageData): boolean; EXPORT;
var img : TFPCustomImage;
    x,y : longint;
begin
   fname := reconstruirString(fname);

   if not FileExists(fname) then exit(False);
   img := TFPMemoryImage.create(1,1);
   if not tryLoadImage(img, fname) then exit(False);

   if imagen = NIL then begin
      imagen := AllocMem(sizeof(TImageData));
   end;

   imagen^.width  := img.width;
   imagen^.height := img.height;

   setLength(imagen^.data, img.width * img.height);

   for y := 0 to img.height-1 do begin
      for x := 0 to img.width-1 do begin
		 try
			imagen^.data[y * img.width + x] := convertPixel( img.Colors[x,y] );
		 except
			imagen^.data[y * img.width + x] := convertPixel( mkColor(0,0,0,0) );
		 end;
      end;
   end;

   try img.Free(); except end;

   RETURN true;
end;

function saveImage(fname : String; imagen:PTImageData; override:boolean = false): boolean;  EXPORT;
var img : TFPCustomImage;
    x,y, l : longint;
begin
   fname := reconstruirString(fname);

   if (FileExists(fname)) and (not override) then exit(false);

   img := TFPMemoryImage.create(imagen^.width, imagen^.height);

   for y := 0 to img.height-1 do begin
      for x := 0 to img.width-1 do begin
         l := (y * img.width + x);
		 try
			img.Colors[x,y] := deconvertPixel( imagen^.data[l] );
		 except 
			img.Colors[x,y] := deconvertPixel( mkPixel(0,0,0,255) );
		 end;
      end;
   end;

   RETURN trySaveImage(img, fname);

   try img.free(); except end;
end;

function scaleImage(imagen : PTImageData; w,h:DWORD; output: PTImageData): boolean;  EXPORT;
var img,img2 : TFPCustomImage;
    canvas : TFPCustomCanvas;
    x,y,LEN : longint;
begin
   if imagen = NIL then EXIT(false);
   if output = NIL then begin
      output := AllocMem(sizeof(TImageData));
   end;

   img  := TFPMemoryImage.create(imagen^.width, imagen^.height);
   for y := 0 to imagen^.height-1 do begin
      for x := 0 to imagen^.width-1 do begin
         try
            img.Colors[x,y] := deconvertPixel( imagen^.data[y * imagen^.width + x] );;
         except
            img.Colors[x,y] := deconvertPixel( mkPixel(0,0,0,255) );
         end;
      end;
   end;
   img2 := TFPMemoryImage.create(w,h);

   canvas := TFPImageCanvas.Create(img2);

   with Canvas as TFPImageCanvas do
     StretchDraw(0,0,w,h, img);

   output^.width  := w;
   output^.height := h;

   LEN := w * h;
   setLength(output^.data, LEN);

   for y := 0 to h-1 do begin
      for x := 0 to w-1 do begin
         try
            output^.data[y * w + x] := convertPixel( img2.Colors[x,y] );
         except
            output^.data[y * w + x] := convertPixel( mkcolor(0,0,0,255) );
         end;
      end;
   end;

   try canvas.free(); except end;
   try img.free(); except end;
   try img2.free(); except end;
end;

type TVersion = array[0..3] of byte;

function version(): TVersion; EXPORT;
begin
   result[0] := VERSION_MAYOR;
   result[1] := VERSION_MINOR;
   result[2] := VERSION_ALPHA;
   result[3] := VERSION_BUILD;
end;

EXPORTS
   init,done
   ,loadImage
   ,saveImage
   ,scaleImage
   ,version
;

{$R *.res}

begin
end.
