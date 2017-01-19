program test
real a(360,181)
integer i,irec
do i = 1,360
 do j =1,181
  a(i,j)=(i+j)*1.
 enddo
enddo
open(10,file='basemap.dat',FORM='UNFORMATTED',ACCESS='DIRECT',RECL=360*181*4)
irec=1
write(10,rec=irec)((a(i,j),i=1,360),j=1,181)
end
