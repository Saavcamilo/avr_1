/*
   This file converts the information in the .LST file input on stdin to test
   vectors which are output to stdout.  Only the instructions are output.

   Revision History:
      2/17/15  Glen George	Initial revision (from 5/11/00 version of
	                        mem2vec.c).
*/




/* library include files */
#include  <ctype.h>
#include  <string.h>
#include  <stdio.h>
#include  <stdlib.h>

/* local include files */
  /* none */


/* definitions */
#define  ALLOC_SIZE	200	/* size of array to allocate at a time */
#define  VEC_PER_LINE   5	/* vectors per line */




int  main()
{
    /* variables */
    char  (*inst)[5] = NULL;		/* test vector instruction */

    char    line[300];			/* a line of input */

    int     no_lines = 0;		/* number of lines processed */

    int     no_vectors = 0;		/* number of vectors stored */
    int     alloc_vectors = 0;		/* number of vectors allocated */

    int     error = 0;			/* error flag */

    int     i;				/* loop index */



    /* read lines until done or error */
    while (!error & (fgets(line, 300, stdin) != NULL))  {

        /* have a line, count it */
	no_lines++;

        /* check if the line is an instruction line */
	if (line[0] == '0')  {

	    /* it is a valid line, do we have room for it */
	    /* note: could have two instruction words */
	    if ((no_vectors + 1) >= alloc_vectors)  {

	        /* need to allocate more memory */
		alloc_vectors += ALLOC_SIZE;
		inst = realloc(inst, alloc_vectors * sizeof(char [5]));
		/* if anything went wrong set the error flag */
		error = (inst == NULL);
            }

	    
            /* if no error, parse the line */
	    if (!error)  {

	        /* instruction follows the first space */
		for (i = 0; ((line[i] != '\0') && !isspace(line[i])); i++);
		/* skip all whitespace */
		while ((line[i] != '\0') && isspace(line[i]))
		    i++;
	        /* get the first word */
		strncpy(inst[no_vectors], &(line[i]), 4);
		inst[no_vectors][4] = '\0';
		/* make sure in uppercase */
		strupr(inst[no_vectors]);
		/* have another vector */
		no_vectors++;

	        /* now the second word, if it exists */
	        if (strncmp(&(line[i + 5]), "    ", 4) != 0)  {

		    /* have a second word in the instruction */
		    strncpy(inst[no_vectors], &(line[i + 5]), 4);
		    inst[no_vectors][4] = '\0';
		    /* make sure in uppercase */
		    strupr(inst[no_vectors]);
		    /* have another vector */
		    no_vectors++;
	        }
	    }
        }
    }


    /* check if there was an error */
    if (error)
        /* have an error - output a message */
	fprintf(stderr, "Out of memory\n");

    /* output summary results */
    fprintf(stderr, "Lines processed: %d\n", no_lines);
    fprintf(stderr, "Vectors generated: %d\n", no_vectors);


    /* finally output the instruction vectors */
    for (i = 0; i < no_vectors; i++)  {
        if ((i % VEC_PER_LINE) == 0)
	    /* need a new line for vectors */
	    putchar('\n');
	printf("X\"%s\", ", inst[i]);
    }

    /* make sure finished off the last line */
    putchar('\n');


    /* done with everything - exit */
    return  0;

}
