#PNG viewer for OpenComputers
##Install
1. Copy all contents except the .php-file to your OC-HDD (not floppy)
2. Run `png.lua` and enter the requested png filename 

##Requirements
- Lua 5.2
- All PNG's must be Truecolor 8-bit, with a maximum resolution of 160x100

##Creating PNG's
1. Make sure you have PHP5 installed on an accessible computer, and have access to it on the command-line
1. Run the following command in the folder where the source-PNG is located: `php to8bit.php filename.png` (where filename.png is the image you want to convert)
1. The copy the PNG to the HDD on your OC-Computer like you would normally do.
####ToDo
1. Create simple PHP-file that you can host online with forms and maybe even a folder where the images are to be placed.
2. Then also make a simple lua-script which can download PNG's from the previous script.
