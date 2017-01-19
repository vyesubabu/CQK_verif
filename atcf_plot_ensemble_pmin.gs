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
xlabel=9.7
ylabel=7.0
while (ifile<=nfile)
*
* open a text file of intensity for each member
*
 fname='intensity_mem_'ifile'.txt'
 rc=read(fname)
 iline=sublin(rc,2)
 fmodel=subwrd(iline,4)
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
 if (fmodel = "OFCL")
  ntime=0
 else
  ntime=itime
 endif
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
 'set vrange 'pmin1' 'pmin2
 'set ylint 10'
 'set cmark 0'
 'set ccolor 0'
 'd a'
 iy=pmin.1
 ix=time.1
 'q gr2xy 'ix' 'iy
 rc=sublin(result,1)
 x1=subwrd(rc,3)
 y1=subwrd(rc,6)
 icount=2
 while (icount <=ntime)
  iy=pmin.icount
  ix=time.icount + 1
  'q gr2xy 'ix' 'iy
  rc=sublin(result,1)
  x2=subwrd(rc,3)
  y2=subwrd(rc,6)
  'set cthick 12'
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
 'set string 'color.ifile' l 7'
 'set strsiz 0.12'
 if (ifile < nfile)
  'draw string 'xlabel' 'ylabel' 'ifile' 'fmodel
 else
  'draw string 'xlabel+0.2' 'ylabel' BEST'
  'draw wxsym 40 'xlabel+0.05' 'ylabel' 0.2 'color.ifile' 9'
 endif
 ylabel=ylabel-0.2
 ifile=ifile+1
endwhile
*
* draw labelS
*
'set string 1 c 9'
'set strsiz 0.18'
'draw string 5.5 8.1 'exp
'draw string 5.5 7.9 Minimum sea level pressure time series'
*'draw string 5.5 7.6 AVNO: Oper. GFS; PRDH: Orig. Hybrid GFS Parallel' 
*'draw string 5.5 7.3 PRD1: Reruns of Hybrid GFS Parallel'
'set string 1 c 9 90'
'draw string 0.32 4.0 PMIN (hPa)' 
'set string 1 c 9 0'
'draw string 5.5 0.5 Forecast lead time (hr)'
*'enable print fig_pmin.gmf'
*'print'
*'disable print'
*'!gxps -c -i fig_pmin.gmf -o fig_pmin.ps'
*'!convert -trim -rotate 90 -geometry 1000x1000 fig_pmin.ps fig_pmin.png'
'printim fig_pmin.png x1024 y768 white'
'!rm -f *.gmf *.ps'
