*
*  [PURPOSE]
*
*  This script is to draw an ensemble of hurricane-track plots.  
*  This script will also plot the best track along the ensemble
*  and it does little error checking on the input file. 
*
*  [HISTORY] - Aug 5 2009: Chanh updated for ensemble plot.  
*            - Jan 19 2012: chanh added fort.14 header file  
*
*  [GUIDE]
*
*  To use this, you first open a ctl file that supposed to cover
*  the entire track. Then prepare an input file as instructed.
*  Next, open the ctl file and PLOT a background map so that 
*  w2xy command is active. At the prompt, type track_plot.gs
*  and enter the input file. Suppose to see some track by now.
*
*  [INPUT]
*
*  1. A set of track file with names: track_mem_${mem}.txt., 
*     which contain the following information (note that there
*     should not have any blank line at the end of file    
*
*     Line 1:  Title
*     Line 2:  Drawing primitives for marks: marktype size 
*     Line 3:  Drawing primitives for lines: color style thickness
*     Line 4:  Starting hour and the interval of plotting points
*              e.g., 0 6 means that track starts at 0 hour and mark 
*              will be plotted every 6 hours.
*     Rest of lines:  hour  long.  lat.
*             e.g.,   0    -70.5  25.0
*                     6    -71.8  25.2
*                            :
*                            : 
*  2. a fort.14 containing: 
*  
*     Line 1: title of ensemble plot
*     Line 2: start_lat, end_lat, start_long, end_long of plotting
*             domain  
*     Line 3: number of ensemble members + 1 of the best track
* 
*  [NOTE]
*
*  Also assumes that a file has been opened (any file, doesn't
*  matter -- the set command doesn't work until a file has been
*  opened).
*
*===================================================================
*
function main()
*
* reading header information
*
scolor=1
rc=read('fort.14')
exp=sublin(rc,2)
rc=read('fort.14')
iline=sublin(rc,2)
slat=subwrd(iline,1)
elat=subwrd(iline,2)
slon=subwrd(iline,3)
elon=subwrd(iline,4)
'q w2xy 'elon' 'slat
rc=sublin(result,1)
xlabel=subwrd(rc,3)
ylabel=subwrd(rc,6)
xlabel=xlabel-1.0
ylabel=ylabel+0.14
say xlabel' 'ylabel
rc=read('fort.14')
nesem = sublin(rc,2) 
*
* pull all track file name
*
ie=1
while (ie <= nesem)
 fname.ie='track_mem_'nesem-ie+1'.txt'
 ie = ie + 1
endwhile
*
* looping thru all files.
*
icount=1
while (icount <=nesem)
fname=fname.icount
say file to be opened' 'fname.icount
*
*  Read the 1st record: Title
*
  ret = read(fname)
  rc = sublin(ret,1)
  if (rc>0) 
      say 'File Error 1'
      return
  endif
  title = sublin(ret,2)
  fmodel = subwrd(title,4)
  say title

*  Read the drawing primitives

  ret = read(fname)
  rc = sublin(ret,1)
  if (rc>0)
     say 'File Error 2' 
     return
  endif
  dpline = sublin(ret,2)
  marktype = subwrd(dpline,1)
  marksize = subwrd(dpline,2)
  ret = read(fname)
  rc = sublin(ret,1)
  if (rc>0)
     say 'File Error 3' 
     return
  endif
  dpline = sublin(ret,2)
  lcolor = subwrd(dpline,1)
  lstyle = subwrd(dpline,2)
  lthick = subwrd(dpline,3)
  say ' marktype, marksize, lcolor, lstyle and lthick:'
  say ' 'marktype ' ' marksize ' ' lcolor ' ' lstyle ' ' lthick
*
* Read starting hour and the interval hours of plotting points
*
  ret = read(fname)
  rc = sublin(ret,1)
  if (rc>0)
     say 'File Error 4'
     return
  endif
  dhour = sublin(ret,2) 
  start = subwrd(dhour,1)
  jump = subwrd(dhour,2)
  say ' starting hour and the interval hours of plotting points:'
  say '  'start' 'jump
*   
*  Read all data points
*
  ret = read(fname)
  rc = sublin(ret,1)
  tcount = 0
  while (rc = 0) 
      tcount = tcount + 1
      loc = sublin(ret,2)
      hour = subwrd(loc,1)
      dtime.tcount = subwrd(loc,1)
      dlong.hour = subwrd(loc,2)
      dlat.hour = subwrd(loc,3)
      ret = read(fname)
      rc = sublin(ret,1)
  endwhile
  ncount = tcount

  if (rc!=2 & rc!=0) 
         say 'File Error 5, rc=' rc
         return
  endif

  endhour = hour
  say ' endhour=' endhour

* Plotting

*  lcolor = scolor 
  'set line 'lcolor' 'lstyle' 'lthick
  'query w2xy 'dlong.start' 'dlat.start
  xprev = subwrd(result,3) 
  yprev = subwrd(result,6) 
  'set strsiz 0.16'
  'set string 'lcolor' c'
  if (icount=nesem)
   'draw wxsym 40 'xprev' 'yprev' 'marksize' 'lcolor' 9'
  else
   'draw string 'xprev' 'yprev' 'icount
  endif
  next = dtime.2 
  tcount = 2
  while (tcount <= ncount)
      'query w2xy 'dlong.next' 'dlat.next
      xnext = subwrd(result,3)
      ynext = subwrd(result,6)
      if (dlat.next<=elat & dlat.next>=slat & dlong.next<=elon & dlong.next >=slon)
       'draw line 'xprev' 'yprev' 'xnext' 'ynext
      endif
      if (icount=1)
       if (dlat.next<=elat & dlat.next>=slat & dlong.next<=elon & dlong.next >=slon)
        'draw wxsym 40 'xnext' 'ynext' 'marksize' 'lcolor' 9'
       endif
      else
       'draw string 'xnext' 'ynext' 'icount-1
      endif
      tcount = tcount + 1
      next = dtime.tcount
      xprev = xnext
      yprev = ynext
  endwhile
  'set string 'lcolor' l 7'
  if (icount > 1)
   'draw string 'xlabel' 'ylabel' 'icount-1' 'fmodel
  else
   'draw string 'xlabel+0.25' 'ylabel' BEST'
   'draw wxsym 40 'xlabel+0.07' 'ylabel' 'marksize' 'lcolor' 9'
  endif
  ylabel=ylabel+0.2
  'set string 1 c 9'
  'set strsiz 0.18'
  'draw string 5.5 8.0 'exp
*  'draw string 5.5 7.7 AVNO: Oper. GFS; PRDH: Orig. Hybrid GFS Parallel'
*  'draw string 5.5 7.4 PRD1: Reruns of Hybrid GFS Parallel'
  say fname ' is working fine.' 
 scolor = scolor + 1 
 icount = icount + 1
endwhile


