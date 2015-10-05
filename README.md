Just a few tools to do bioanth things.

You're going to need Ruby to run these things.  If you have a Mac or
Linux, you probably already have Ruby.  If you have Windows, go install
Ruby.


## MMD 

`mmd.rb` calculates the mean measure of divergence between two or more
populations.  Each population is given in a separate input file, like:

```bash
./mmd.rb population1.csv population2.csv
```

The population files are CSV (comma-separated value) files in which the
first line is a header with the word `Site` and one or more trait names.
Like so:

```csv
Site,trait1,trait2,trait3
```

The rest of the file describes measurements for each individual, with one
individual per line.  Those lines have the site name -- which should be
the same for all individuals in a file -- and values for that individual
for all the traits listed in the header.  Like so:

```csv
Site123,2,0,1
```

When you run `mmd.rb` on two such files, you'll get some mathy output that
means something to biological anthropologists.
