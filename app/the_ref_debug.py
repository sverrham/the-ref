
import serial
import time
import struct

ser = serial.Serial('COM3', 9800, timeout=0)
s = ser.read(100)

#readout and decode debug data from fpga, simplesimple.
for i in range(100):
    s += ser.read(100)
    #print(s)
    while True:
        if len(s) < 2:
            break    
        type = s[0]
        length = s[1]
        if len(s) < 2+length:
            break
        val = 0
        if length == 4+2:
          val = struct.unpack('l', s[2:length])[0] 
        
        
        if s[2+length-2:2+length] != b'\r\n':
            # Not correct parsed stream...
            print(s[2+length-2:2+length])

        s = s[2+length:]

        print("Type: {} val: {}".format(type, val))
    s = ser.read(1)
    time.sleep(1)
    