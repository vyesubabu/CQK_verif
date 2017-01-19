'reinit'
'open basemap.ctl'
'set parea 0.5 10.7 0.5 7.6'
'set xlopts 1 7 0.16'
'set ylopts 1 7 0.16'
'set map 15 1 5'
rc=read('fort.14')
rc=read('fort.14')
iline=sublin(rc,2)
slat=subwrd(iline,1)
elat=subwrd(iline,2)
slon=subwrd(iline,3)
elon=subwrd(iline,4)
dlat=((elat-slat)/5)
dlon=((elon-slon)/5)
'set lat 'slat' 'elat
'set lon 'slon' 'elon
'set mpdset hires'
'set cmin 500'
'set xlint 5'
'set ylint 5'
'set grads off'
'set ccolor 0'
'd a'
*'basemap.gs O 11 1 M'
'basemap.gs L 15 1 M'
'set cmin 10000'
'd lat'
'atcf_plot_ensemble_all_track.gs'
*'enable print fig_track.gmf'
*'print'
*'disable print'
*'!gxps -c -i fig_track.gmf -o fig_track.ps'
*'!convert -trim -rotate 90 -geometry 1000x1000 fig_track.ps fig_track.png'
'printim fig.png x1024 y768 white'
'!convert -trim fig.png fig_track.png'
'!rm *.gmf *.ps'
