MZ700RomToVhdl.exe

  MZ-700 on FPGA for Spartan-3(XC3S200)用
  ROMデータ→VHDLソース生成ツール

概要

・C#で記述しております。
・EXEファイルは、.NET Framework 1.1 SP1 以上がインストールされている
　PCで実行可能です。

使い方

1)MZ700RomToVhdl.exe、MZ700RomToVhdl.txt と同じディレクトリに配置します。
　・MZ700RomToVhdl.txtは、mz700fpga_X200_051025.lzhに含まれる、
　　mrom.vhdの固定部分を切り出して作成しています。
　　mz700fpga_X200_051025.lzh以外の媒体とは異なる場合がありますので、
　　mrom.vhdに修正がある場合は、適宜作成しなおす必要があります。
　・MZ700RomToVhdl.txt内に記述している、%1%, %2%に、ROMデータを組み込む
　　ための記述が追加されます。
2) 1)と同じディレクトリに1Z009.ROMを配置します。
3) コマンドプロンプトで、1)のディレクトリに移動します。
4) コマンドを実行します。

＜例＞
  >cd D:\FPGA\MZ-700\MZ700RomToVhdl
  >MZ700RomToVhdl.exe 1Z009.ROM > mrom.vhd

5)生成されたmrom.vhdを、MZ-700 on FPGAの開発環境にコピーします。
6)Xilinx ISE 7.1iで、bin,mcsを生成します。

※細かいエラーチェックは全く行っておりません。指定するファイルは、
　正しいROMデータであることを保障する必要があります。

＜リンク＞

.NET Framework 
http://www.microsoft.com/japan/msdn/netframework/

MZ-700を作る
  MZ-700 on FPGA for Spartan-3(XC3S200)
http://www.retropc.net/ohishi/mzbyfpga/index.htm


謝辞

MZ-700 on FPGA for Spartan-3(XC3S200)を開発してくださった、
Ｏｈ！石さんにお礼を申し上げます。

