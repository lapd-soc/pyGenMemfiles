import sys
import os
import platform

def err(info):
	print (info)
	sys.exit(1)

#__main__
if __name__ == '__main__':
	if len(sys.argv) == 1:
		err('ERROR: You must enter the program directory.\nExample: python createMemfiles.py C_Example')
	if os.path.exists(sys.argv[1]) == False:
		err('Directory "%s" not exit' % sys.argv[1])
	indir = sys.argv[1] + '/'
	outputdir = indir + 'MemoryFiles/'

	if os.path.exists(outputdir):
		print('"%s" directory exists' % outputdir)
	else:
		print('mkdir "%s"' % outputdir)
		os.makedirs(outputdir)

	infilename = indir + 'FPGA_Ram_modelsim.txt'

	outfilename_boot = outputdir + 'ram_reset_init.txt'
	outfilename_program = outputdir + 'ram_program_init.txt'

	outfilename_bootmif = outputdir + 'ram_reset_init.mif'
	outfilename_programmif = outputdir + 'ram_program_init.mif'

	addr_mask = 0xFFFFF #low 5 hex digits of the address

	#os.system('cd %s && make' % indir) #-----------make---------------

	if os.path.exists(infilename) == False:
		err('file "FPGA_Ram_modelsim.txt" not exit')

	#/r/n
	sysstr = platform.system()
	if (sysstr.find("Windows") != -1) or (sysstr.find("NT") != -1):
		newlinetag = '\r\n'
	else:
		newlinetag = '\n'
	

	#openfile
	infile = open(infilename, 'r')

	outfile_boot = open(outfilename_boot, 'w')
	outfile_program = open(outfilename_program, 'w')

	outfile_bootmif = open(outfilename_bootmif, 'w')
	outfile_programmif = open(outfilename_programmif, 'w')

	#initialize mif
	outfile_bootmif.write('WIDTH = 32; %s' % newlinetag)
	outfile_bootmif.write('DEPTH = 32768; %s' % newlinetag)
	outfile_bootmif.write('ADDRESS_RADIX = HEX; %s' % newlinetag)
	outfile_bootmif.write('DATA_RADIX = HEX; %s' % newlinetag)
	outfile_bootmif.write('CONTENT BEGIN %s' % newlinetag)
	outfile_programmif.write('WIDTH = 32; %s' % newlinetag)
	outfile_programmif.write('DEPTH = 65536; %s' % newlinetag)
	outfile_programmif.write('ADDRESS_RADIX = HEX; %s' % newlinetag)
	outfile_programmif.write('DATA_RADIX = HEX; %s' % newlinetag)
	outfile_programmif.write('CONTENT BEGIN %s' % newlinetag)

	#skip first 6 line
	memfiles = infile.readlines()

	for i in memfiles[6:]:
		tmp = i.replace(':',' ').split()
		if (len(tmp) < 2):
			continue
		if (len(tmp[0])!=8) and not all(c in '0123456789xabcdef' for c in tmp[0]):
			continue
		addr = int(tmp[0], 16)

		if (tmp[1][0]=='<'):
			if (addr >= 0x90000000):
				outfile_boot.write('@%X \t%s' % (((addr&addr_mask)/4), newlinetag)) #low 5 hex digits of the address
			elif (addr >= 0x80000000):
				outfile_program.write('@%X \t%s' % (((addr&addr_mask)/4), newlinetag))
			continue
		if not all(c in '0123456789xabcdef' for c in tmp[1]):
			continue

		instruction = int(tmp[1], 16)
		if (addr >= 0x90000000):
			outfile_boot.write('%08x \t%s' % (instruction, newlinetag))
			outfile_bootmif.write('%X : %08x; %s' % (((addr&addr_mask)/4), instruction, newlinetag))
		elif (addr >= 0x80000000):
			outfile_program.write('%08x \t%s' % (instruction, newlinetag))
			outfile_programmif.write('%X : %08x; %s' % (((addr&addr_mask)/4), instruction, newlinetag))
			
	#end
	outfile_bootmif.write('END; %s' % newlinetag)
	outfile_programmif.write('END; %s' % newlinetag)

	#close file
	infile.close()
	outfile_boot.close()
	outfile_program.close()
	outfile_bootmif.close()
	outfile_programmif.close()
	print ('Memfiles created successfully.')
		