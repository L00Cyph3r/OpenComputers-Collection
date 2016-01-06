<?php
function ImageTrueColorToPalette2($image, $dither, $ncolors) {
	$width = imagesx( $image );
	$height = imagesy( $image );
	$colors_handle = ImageCreateTrueColor( $width, $height );
	ImageCopyMerge( $colors_handle, $image, 0, 0, 0, 0, $width, $height, 100 );
	ImageTrueColorToPalette( $image, $dither, $ncolors );
	ImageColorMatch( $colors_handle, $image );
	ImageDestroy($colors_handle);
	return $image;
}
if (isset($argv[1])) {
	if (is_file($argv[1]) && is_readable($argv[1])) {
		
		$src = imagecreatefrompng($argv[1]);
		$width = imagesx($src);
		$height = imagesy($src);
		$width = 160;
		$height = 100;
		$dstimage=imagecreatetruecolor($width,$height);
		$srcimage=imagecreatefrompng($argv[1]);
		imagecopyresampled($dstimage,$srcimage,0,0,0,0, $width,$height,$width,$height);
		
		imagepng($dstimage,join('',explode('.',$argv[1],-1)).'-8b.png');
	} else {
		echo "Given file could not be found\n";
		exit;
	}
}