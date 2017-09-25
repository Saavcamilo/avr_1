/*
   This file converts the information in the .asm file input on stdin to test
   vectors which are output to stdout.  The file has a very fixed format which
   must be followed when creating the .asm file.  For any line that accesses
   data memory the comment must start with R or W (for read or write),
   followed by the data to the read or written, and the address it is read
   from or written to (space separated).  A skeleton VHDL test file is then
   output to stdout.



   Revision History:
      2/24/17  Glen George      Initial revision.
*/




/* library include files */
#include  <ctype.h>
#include  <stdio.h>
#include  <stdlib.h>
#include  <string.h>

/* local include files */
  /* none */


/* definitions */
#define  ALLOC_SIZE     200     /* size of array to allocate at a time */
#define  MAX_LINE_SIZE  300     /* maximum length of a line */
#define  VEC_PER_LINE   5       /* vectors per line */


/*

    First argument is name of input .asm file
    Second argument is name of output .txt file where skeleton vhdl template 
    is printed out
*/

int  main(int argc, char **argv)
{
    /* variables */
    char  (*data)[3] = NULL;            /* test vector data */
    char  (*rdwr)[2] = NULL;            /* test vector read/write direction */
    char  (*addr)[5] = NULL;            /* test vector address */

    char    line[MAX_LINE_SIZE];        /* a line of input */

    int     no_lines = 0;               /* number of lines processed */

    int     no_vectors = 0;             /* number of vectors stored */
    int     alloc_vectors = 0;          /* number of vectors allocated */

    int     error = 0;                  /* error flag */

    int     i;                          /* loop index */

    FILE *f = fopen(argv[1], "r");
    FILE *f2;

    /* read lines until done or error */
    while (!error & (fgets(line, MAX_LINE_SIZE, f) != NULL))  {

        /* have a line, count it */
        no_lines++;

        /* have a valid line, do we have room for it */
        if (no_vectors >= alloc_vectors)  {

            /* need to allocate more memory */
            alloc_vectors += ALLOC_SIZE;
            data = realloc(data, alloc_vectors * sizeof(char [3]));
            rdwr = realloc(rdwr, alloc_vectors * sizeof(char [2]));
            addr = realloc(addr, alloc_vectors * sizeof(char [5]));

            /* if anything went wrong set the error flag */
            error = ((data == NULL) || (rdwr == NULL) || (addr == NULL));
        }

            
        /* if no error, parse the line */
        if (!error)  {

            /* read/write follows the semi-colon */
            for (i = 0; ((line[i] != '\0') && (line[i] != ';')); i++);

            /* now need to see read or write */
            if ((line[i + 1] == 'r') || (line[i + 1] == 'R'))  {
                /* have a read cycle */
                strcpy(rdwr[no_vectors], "r");
                /* move past the r/w symbol */
                i += 2;
            }
            else if ((line[i + 1] == 'w') || (line[i + 1] == 'W'))  {
                /* have a write cycle */
                strcpy(rdwr[no_vectors], "w");
                /* move past the r/w symbol */
                i += 2;
            }
            else  {
                /* neither read nor write */
                strcpy(rdwr[no_vectors], " ");
            }


	    /* if have a read or write cycle, need get data and address */
            if (rdwr[no_vectors][0] != ' ')  {

                strncpy(data[no_vectors], &(line[i]), 2);
                data[no_vectors][2] = '\0';
                /* move past the dat value */
                i += 2;

                /* address follows the space after the data */
                while ((line[i] != '\0') && isspace(line[i]))
                    i++;
                strncpy(addr[no_vectors], &(line[i]), 4);
                addr[no_vectors][4] = '\0';
            }

            /* have another vector */
            no_vectors++;
        }
    }

    fclose(f);


    f2 = fopen(argv[2], "w+");

    /* check if there was an error */
    if (error)
        /* have an error - output a message */
        printf("Out of memory\n");

    /* output summary results */
    printf("Lines processed: %d\n", no_lines);
    printf("Vectors generated: %d\n", no_vectors);


    /* output header information */
    fputs("library ieee;\n", f2);
    fputs("use ieee.std_logic_1164.all;\n", f2);
    fputs("use ieee.std_logic_arith.all;\n", f2);
    fputs("use ieee.std_logic_unsigned.all;\n", f2);
    fputs("use ieee.numeric_std.all;\n", f2);
    fputs("\n", f2);
    fputs("library OpCodes;\n", f2);
    fputs("use OpCodes.OpCodes.all;\n", f2);
    fputs("\n", f2);
    fputs("\n", f2);
    fputs("entity cpu_test_tb is", f2);
    fputs("end cpu_test_tb;\n", f2);
    fputs("\n", f2);
    fputs("\n", f2);
    fputs("architecture TB_ARCHITECTURE of cpu_test_tb is", f2);
    fputs("\n", f2);
    fputs("\n", f2);
    fputs("\n", f2);
    fputs("    -- Stimulus signals - signals mapped to the input and inout ports of tested entity", f2);
    fputs("    signal  Clock    :  std_logic;\n", f2);
    fputs("    signal  Reset    :  std_logic;\n", f2);
    fputs("    signal  DataDB   :  std_logic_vector(7 downto 0);\n", f2);
    fputs("\n", f2);
    fputs("    -- Observed signals - signals mapped to the output ports of tested entity", f2);
    fputs("    signal  DataRd   :  std_logic;\n", f2);
    fputs("    signal  DataWr   :  std_logic;\n", f2);
    fputs("    signal  DataAB   :  std_logic_vector(15 downto 0);\n", f2);
    fputs("\n", f2);
    fputs("    --Signal used to stop clock signal generators", f2);
    fputs("    signal  END_SIM  :  BOOLEAN := FALSE;\n", f2);
    fputs("\n", f2);
    fputs("    -- test value types", f2);
    fputs("    type  byte_array    is array (natural range <>) of std_logic_vector(7 downto 0);\n", f2);
    fputs("    type  addr_array    is array (natural range <>) of std_logic_vector(15 downto 0);\n", f2);


    /* finally output the test vectors */

    /* the read vector */
    fputs("\n-- expected data bus write signal for each instruction", f2);
    fprintf(f2, "signal  DataRdTestVals  :  std_logic_vector(0 to %d) :=\n", no_vectors - 1);
    fprintf(f2, "    \"");
    for (i = 0; i < no_vectors; i++)  {
        if (rdwr[i][0] == 'r')
            /* have a read signal */
            fputs("0", f2);
        else
            /* no read signal */
            fputs("1", f2);
    }
    fprintf(f2, "\";\n");

    /* then the write vector */
    fputs("\n-- expected data bus read signal for each instruction", f2);
    fprintf(f2, "signal  DataWrTestVals  :  std_logic_vector(0 to %d) :=\n", no_vectors - 1);

    fprintf(f2, "    \"");
    for (i = 0; i < no_vectors; i++)  {
        if (rdwr[i][0] == 'w')
            /* have a read signal */
            fputs("0", f2);
        else
            /* no read signal */
            fputs("1", f2);
    }
    fprintf(f2, "\";\n");

    /* next the data vectors */
    fputs("\n-- supplied data bus values for each instruction (for read operations)", f2);
    fprintf(f2, "signal  DataDBVals      :  byte_array(0 to %d) := (", no_vectors - 1);
    for (i = 0; i < no_vectors; i++)  {
        if ((i % VEC_PER_LINE) == 0)
            /* need a new line for vectors */
            fprintf(f2, "\n    ");
        /* check if have a vector */
        if (rdwr[i][0] == 'r')
            /* reading - put the data out */
            fprintf(f2, "X\"%s\"", data[i]);

        else
            /* not reading - high-Z */
            fprintf(f2, "\"ZZZZZZZZ\"");
        /* add termination based on whether last vector */
        if (i != (no_vectors - 1))  {
            if (rdwr[i][0] == 'r')
                /* reading - need comma and lots of spaces */
                fprintf(f2, ",      ");
            else
                /* not reading - only need comma and space */
                fprintf(f2, ", ");
        }
        else  {
            /* end of the vector, terminate the vector */
            fputs(" );\n", f2);
        }
    }

    fputs("\n-- expected data bus output values for each instruction (only has a value on writes)", f2);
    fprintf(f2, "signal  DataDBTestVals  :  byte_array(0 to %d) := (", no_vectors - 1);
    for (i = 0; i < no_vectors; i++)  {
        if ((i % VEC_PER_LINE) == 0)
            /* need a new line for vectors */
            fprintf(f2, "\n    ");
        /* check if have a vector */
        if (rdwr[i][0] == 'w')
            /* have a vector - output it for comparison */
            fprintf(f2, "X\"%s\"", data[i]);
        else
            /* no vector - don't do a compare */
            fprintf(f2, "\"--------\"");
        /* add termination based on whether last vector */
        if (i != (no_vectors - 1))  {
            if (rdwr[i][0] == 'w')
                /* writing - need comma and lots of spaces */
                fprintf(f2, ",      ");
            else
                /* not writing - only need comma and space */
                fprintf(f2, ", ");
        }
        else  {
            /* end of the vector, terminate the vector */
            fputs(" );\n", f2);
        }
    }

    /* finally the address vectors */
    fputs("\n-- expected data addres bus values for each instruction", f2);
    fprintf(f2, "signal  DataABTestVals  :  addr_array(0 to %d) := (", no_vectors - 1);
    for (i = 0; i < no_vectors; i++)  {
        if ((i % VEC_PER_LINE) == 0)
            /* need a new line for vectors */
            fprintf(f2, "\n    ");
        /* check if have a vector */
        if ((rdwr[i][0] == 'r') || (rdwr[i][0] == 'w'))
            /* have a vector - output it */
            fprintf(f2, "X\"%s\"", addr[i]);
        else
            /* no vector - don't do a compare */
            fprintf(f2, "\"----------------\"");
        /* add termination based on whether last vector */
        if (i != (no_vectors - 1))  {
            if ((rdwr[i][0] == 'r') || (rdwr[i][0] == 'w'))
                /* have a vector - need comma and lots of spaces */
                fprintf(f2, ",            ");
            else
                /* no vector - only need comma and space */
                fprintf(f2, ", ");
        }
        else  {
            /* end of the vector, terminate the vector */
            fputs(" );\n", f2);
        }
    }

    /* finish off any remaining line */
    fputs("\n", f2);

    fclose(f2);


    /* done with everything - exit */
    return  0;

}
