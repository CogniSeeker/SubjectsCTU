CFLAGS+=  -pedantic -Wall -std=c99 -O3
HW=hw04-b3b36prg
ZIP=zip

$(HW): grep.c 
	$(CC) $(CFLAGS) grep.c -o $(HW)

zip:
	$(ZIP) $(HW)-brute.zip grep.c

clean:
	$(RM) *.o
	$(RM) $(HW)
	$(RM) $(HW)-brute.zip

.PHONY: clean zip