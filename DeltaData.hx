/*
** DeltaData.hx
**
** Copyright (c) 2011 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class DeltaData
{
    public var shaping_acc:Array<Int>;
    public var shaping_delta:Array<Int>;
    public var error:Array<Int>;

    public function new()
    {
        error = new Array();
        error[0] = 0;
        error[1] = 0;
        shaping_acc = new Array();
        shaping_acc[0] = 0;
        shaping_acc[1] = 0;
        shaping_delta = new Array();
        shaping_delta[0] = 0;
        shaping_delta[1] = 0;
    }
}
