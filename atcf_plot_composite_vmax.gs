'reinit'
'open basemap.ctl'
'set parea 1.0 10.5 0.9 7.2'
'set xlopts 1 7 0.16'
'set ylopts 1 7 0.16'
*
* reading header infomation fort.14 to set the 
* scale of x axis
*
rc=read('fort.14')
exp=sublin(rc,2)
rc=read('fort.14')
rc=read('fort.14')
nfile=sublin(rc,2)
rc=read('fort.14')
max1=sublin(rc,2)
rc=read('fort.14')
max2=sublin(rc,2)
if (max1 > max2)
 xmax=max1
else
 xmax=max2
endif
rc=read('fort.14')
vmax1=sublin(rc,2)
rc=read('fort.14')
vmax2=sublin(rc,2)
rc=read('fort.14')
pmin1=sublin(rc,2)
rc=read('fort.14')
pmin2=sublin(rc,2)
say 'max time xaxis is 'xmax
ifile=1
xlabel=10.4
ylabel=7.10
while (ifile<=nfile)
*
* open a text file of intensity for each member
*
 fname='intensity_mem_'ifile'.txt'
 rc=read(fname)
 iline=sublin(rc,2)
 cycle=subwrd(iline,7)
 rc=read(fname)
 rc=read(fname)
 iline=sublin(rc,2)
 color.ifile=subwrd(iline,1)
 rc=read(fname)
 itime=0
 rc=read(fname)
 eof=sublin(rc,1)
 while (eof=0)
  itime=itime+1
  iline=sublin(rc,2) 
  time.itime=subwrd(iline,1) 
  pmin.itime=subwrd(iline,2)
  vmax.itime=subwrd(iline,3)
*  say 'Data line is 'time.itime' 'pmin.itime' 'vmax.itime
  rc=read(fname)
  eof=sublin(rc,1)
 endwhile
 ntime=itime
 say 'Number of datum for plotting is 'ntime
*
* plotting error
*
 'set strsiz 0.14'
 'set grads off'
 'set lat 0'
 'set lon 0 'xmax
 if (xmax > 120)
  'set xaxis 0 'xmax' 24'
 else
  'set xaxis 0 'xmax' 12'
 endif
 'set vrange 'vmax1' 'vmax2
 'set ylint 20'
 'set cmark 0'
 'set ccolor 0'
 'd a'
 iy=vmax.1
 ix=time.1
 'q gr2xy 'ix' 'iy
 rc=sublin(result,1)
 x1=subwrd(rc,3)
 y1=subwrd(rc,6)
 icount=2
 while (icount <=ntime)
  iy=vmax.icount
  ix=time.icount + 1
  'q gr2xy 'ix' 'iy
  rc=sublin(result,1)
  x2=subwrd(rc,3)
  y2=subwrd(rc,6)
  'set line 'color.ifile' 1 9'
  'set string 'color.ifile' c 9'
  'set strsiz 0.16'
  'draw line 'x1' 'y1' 'x2' 'y2
  if (ifile < nfile)
   'draw string 'x2' 'y2' 'ifile
  else
   'draw wxsym 40 'x2' 'y2' 0.2 'color.ifile' 9'
  endif  
  x1=x2
  y1=y2
  icount=icount+1
 endwhile
 'set string 'color.ifile' r 7'
 'set strsiz 0.12'
 if (ifile < nfile)
  'draw string 'xlabel' 'ylabel' 'ifile' 'cycle
 else
  'draw string 'xlabel-0.05' 'ylabel' BEST TRACK'
  'draw wxsym 40 'xlabel-1.35' 'ylabel' 0.2 'color.ifile' 9'
 endif
 ylabel=ylabel-0.2
 ifile=ifile+1
endwhile
*
* draw labelS
*
'set strsiz 0.1'
'set lat 64'
'set ccolor 1'
'set cthick 5'
'set cstyle 3'
'set cmark 0'
'd lat'
'q gr2xy 'xmax' 64'
rc=sublin(result,1)
x2=subwrd(rc,3)
y2=subwrd(rc,6)
'draw string 'x2+0.5' 'y2' Cat 1'
'set lat 83'
'set ccolor 1'
'set cthick 5'
'set cstyle 3'
'set cmark 0'
'd lat'
'q gr2xy 'xmax' 83'
rc=sublin(result,1)
x2=subwrd(rc,3)
y2=subwrd(rc,6)
'draw string 'x2+0.5' 'y2' Cat 2'
'set lat 96'
'set ccolor 1'
'set cthick 5'
'set cstyle 3'
'set cmark 0'
'd lat'
'q gr2xy 'xmax' 96'
rc=sublin(result,1)
x2=subwrd(rc,3)
y2=subwrd(rc,6)
'draw string 'x2+0.5' 'y2' Cat 3'
'set lat 113'
'set ccolor 1'
'set cthick 5'
'set cstyle 3'
'set cmark 0'
'd lat'
'q gr2xy 'xmax' 113'
rc=sublin(result,1)
x2=subwrd(rc,3)
y2=subwrd(rc,6)
'draw string 'x2+0.5' 'y2' Cat 4'
'set lat 137'
'set ccolor 1'
'set cthick 5'
'set cstyle 3'
'set cmark 0'
'd lat'
'q gr2xy 'xmax' 137'
rc=sublin(result,1)
x2=subwrd(rc,3)
y2=subwrd(rc,6)
'draw string 'x2+0.5' 'y2' Cat 5'
'set strsiz 0.12'
'set string 1 c 9'
'set strsiz 0.18'
'draw string 5.5 7.9 'exp
'draw string 5.5 7.6 Maximum 10-m wind time series'
'set string 1 c 9 90'
'draw string 0.32 4.0 VMAX (knt)' 
'set string 1 c 9 0'
'draw string 5.5 0.5 Forecast lead time (hr)'
'enable print fig_vmax.gmf'
'print'
'disable print'
'!gxps -c -i fig_vmax.gmf -o fig_vmax.ps'
'!convert -trim -rotate 90 -geometry 1000x1000 fig_vmax.ps fig_vmax.png'
'!rm -f *.gmf *.ps'
