using System;
using System.IO;
using System.Text;

class MZ700RomToVhdl
{

	static int Main(string[] args)
	{
		if (args.Length == 0)
		{
			Console.WriteLine("Please enter a filename.");
			return 1; 
		}
		string path = args[args.Length-1];

		StringBuilder sb1 = new StringBuilder();
		StringBuilder sb2 = new StringBuilder();
		StringBuilder sb = sb1;

		FileStream fs = File.OpenRead(path);
		using(BinaryReader br = new BinaryReader(fs))
		{
			for(int line = 0;;line++)
			{
				if(line >= 128)
				{
					break;
				}
				sb.Append(String.Format("\t\tINIT_{0:X2} => X\"", line < 64 ? line : line - 64));
				for(int count = 0; count < 32; count++)
				{
					sb.Append(String.Format("{0:X2}", br.ReadByte()));
				}
				sb.Append("\",");
				sb.Append(Environment.NewLine);
				if(line == 63)
				{
					sb = sb2;
				}
			}
		}

		string template;
		using(StreamReader sr = new StreamReader(@"MZ700RomToVhdl.txt", Encoding.Default))
		{
			template = sr.ReadToEnd();
		}
		string result = template.Replace("%1%", sb1.ToString());
		result = result.Replace("%2%", sb2.ToString());
		Console.WriteLine(result);

		return 0;
	}
}
