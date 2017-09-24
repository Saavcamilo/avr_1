#include <iostream>
#include <fstream>
#include <string>

using namespace std;



/* 1st argument is name of input hex file
   2nd argument is name of output binary file
*/
int main(int argc, char **argv)
{

	string line;
	ifstream hexfile;
	ofstream binfile;

	char instruction[4];

	hexfile.open(argv[1], ios::in);
	binfile.open(argv[2], ios::out | ios::trunc);

	if (binfile.is_open() && hexfile.is_open())
	{

    	while (getline(hexfile,line))
	    {

	    	for (int i = 9; i+2 < line.length() - 2; i+=4)
	    	{
	    		
	    		instruction[0] = line[i+2];
	    		instruction[1] = line[i+3];
	    		instruction[2] = line[i];
	    		instruction[3] = line[i+1];


	    		for (int j = 0; j < 4; ++j)
	    		{
	    			if (instruction[j] == '0')
	    			{
	    				binfile << "0000";
	    			}
	    			else if (instruction[j] == '1')
	    			{
	    				binfile << "0001";
	    			}
	    			else if (instruction[j] == '2')
	    			{
	    				binfile << "0010";
	    			}
	    			else if (instruction[j] == '3')
	    			{
	    				binfile << "0011";
	    			}
	    			else if (instruction[j] == '4')
	    			{
	    				binfile << "0100";
	    			}
	    			else if (instruction[j] == '5')
	    			{
	    				binfile << "0101";
	    			}
	    			else if (instruction[j] == '6')
	    			{
	    				binfile << "0110";
	    			}
	    			else if (instruction[j] == '7')
	    			{
	    				binfile << "0111";
	    			}
	    			else if (instruction[j] == '8')
	    			{
	    				binfile << "1000";
	    			}
	    			else if (instruction[j] == '9')
	    			{
	    				binfile << "1001";
	    			}
	    			else if (instruction[j] == 'A')
	    			{
	    				binfile << "1010";
	    			}
	    			else if (instruction[j] == 'B')
	    			{
	    				binfile << "1011";
	    			}
	    			else if (instruction[j] == 'C')
	    			{
	    				binfile << "1100";
	    			}
	    			else if (instruction[j] == 'D')
	    			{
	    				binfile << "1101";
	    			}
	    			else if (instruction[j] == 'E')
	    			{
	    				binfile << "1110";
	    			}
	    			else if (instruction[j] == 'F')
	    			{
	    				binfile << "1111";
	    			}
	    		}

	    		binfile << "\n";

	    	}

	    }

    	binfile.close();
    	hexfile.close();
	}
	else
	{
		cout << "Unable to open either or both of the files";
	}



	return 0;
}
