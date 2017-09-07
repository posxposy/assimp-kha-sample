package;

import kha.System;

class Main 
{
    public static inline var WIDTH:Int = 1024;
    public static inline var HEIGHT:Int = 768;
    
    public static function main():Void
    {
        System.init({title: "Sample", width: WIDTH, height: HEIGHT}, function():Void {
            new Project();
        });
    }
}
