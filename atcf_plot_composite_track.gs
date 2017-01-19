'reinit'
'open basemap.ctl'
'set parea 0.7 10.4 0.7 7.3'
'set xlopts 1 7 0.14'
'set ylopts 1 7 0.14'
rc=read('fort.14')
rc=read('fort.14')
iline=sublin(rc,2)
slat=subwrd(iline,1)
elat=subwrd(iline,2)
slon=subwrd(iline,3)
elon=subwrd(iline,4)
dlat=((elat-slat)/5)
dlon=((elon-slon)/5)
'set map 15 1 7'
'set lat 'slat' 'elat
'set lon 'slon' 'elon
'set mpdset hires'
'set cmin 500'
'set xlint 5'
'set ylint 5'
'set grads off'
'd a'
*'basemap.gs O 11 1 M'
'basemap.gs L 15 1 M'
'atcf_plot_composite_all_track.gs'
'enable print fig_track.gmf'
'print'
'disable print'
'!gxps -c -i fig_track.gmf -o fig_track.ps'
'!convert -rotate 90 -trim -geometry 700x700 fig_track.ps fig_track.png'
'!rm *.gmf *.ps'
