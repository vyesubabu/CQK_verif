      PROGRAM extrack_track_actf
      IMPLICIT none
      INTEGER, PARAMETER :: nmax=1000                   ! max num of data length
      INTEGER, PARAMETER :: nbin=17                     ! number of intensity bin
      INTEGER            :: pmin_h(nmax)                ! pmin-hwrf forecast
      INTEGER            :: vmax_h(nmax)                ! vmax-hwrf forecast
      REAL               :: lat_h(nmax)                 ! lat-hwrf forecast
      REAL               :: lon_h(nmax)                 ! lon-hwrf forecast
      INTEGER            :: itim_h(nmax)                ! hwrf forecast time
      INTEGER            :: pmin_o(nmax),pmin_p(nmax)   ! pmin obs
      INTEGER            :: vmax_o(nmax),vmax_p(nmax)   ! vmax obs
      REAL               :: lat_o(nmax)                 ! lat-obs
      REAL               :: lon_o(nmax)                 ! lon-obs
      INTEGER            :: itim_o(nmax)                ! obs time
      REAL               :: pmin_err(nmax)              ! pmin error for each cycle
      REAL               :: vmax_err(nmax)              ! vmax error for each cycle
      REAL               :: lat_err(nmax)               ! latitude track error
      REAL               :: lon_err(nmax)               ! longitude track error
      REAL               :: trak_err(nmax)              ! total track error 
      REAL               :: cross_err(nmax)             ! cross track error (+ right; - left)
      REAL               :: along_err(nmax)             ! along track error (+ fast; - slow)
      REAL               :: lato1,lono1,lato2,lono2     ! dump vars
      REAL               :: latf,lonf,aerr,cerr         ! dump vars
      INTEGER            :: hcount                      ! number of hwrf forecast
      INTEGER            :: ocount                      ! number of obs time
      INTEGER            :: bcount                      ! number of hwrf initial cycle
      INTEGER            :: nmatch                      ! dump var
      INTEGER            :: dt                          ! output interval
      INTEGER            :: flag_filter                 ! flag for filter
      INTEGER            :: i,j,k,m                     ! dump var
      INTEGER            :: irec,debug,ista,iend        ! debugging
      REAL               :: mis                         ! missing value
      CHARACTER*100      :: ofile1,ofile2,ofile3        ! dump var
!
! define intensity bin. 
!
      mis         = -99999
      irec        = 1
      debug       = 1
      dt          = 6
      PRINT*,'Enter input files'
      READ*,ofile1
      READ*,ofile2
      PRINT*,'forecast file is: ',ofile1(1:30)
      PRINT*,'obs input file is: ',ofile2(1:30)
!
! zero the buffer arrays
!
      pmin_err    = mis
      vmax_err    = mis
      lat_err     = mis
      lon_err     = mis
      cross_err   = mis
      along_err   = mis
      trak_err    = mis
      pmin_h      = mis
      vmax_h      = mis
      pmin_p      = mis
      vmax_p      = mis
!
! reading the HWRF forecast first. Note that the forecast time has to
! to be cacluated externally and saved in fort.10
!
      flag_filter = 1 
      CALL input_file(ofile1,lat_h,lon_h,pmin_h,vmax_h,itim_h,hcount,nmax,flag_filter)
      PRINT*,'Number of HWRF data forecast record is: ',hcount
      IF (debug.eq.1) THEN
       DO i       = 1,hcount
        WRITE(*,'(1I3,1I12,2F7.2,2I5)')i,itim_h(i),lat_h(i),lon_h(i),pmin_h(i),vmax_h(i)
       ENDDO
      ENDIF
!
! reading observation
!
      flag_filter = 1
      CALL input_file(ofile2,lat_o,lon_o,pmin_o,vmax_o,itim_o,ocount,nmax,flag_filter)
      PRINT*,'Number of OBS data record is: ',ocount
      IF (debug.eq.1) THEN
       DO i       = 1,ocount
        WRITE(*,'(1I3,1I12,2F7.2,2I5)')i,itim_o(i),lat_o(i),lon_o(i),pmin_o(i),vmax_o(i)
       ENDDO
      ENDIF
!
! compute next error of the HWRF forecast valid for each
! obs time
!
      DO i        = 1,hcount
       pmin_err(i)= mis
       vmax_err(i)= mis
       lat_err(i) = mis
       lon_err(i) = mis
       cross_err(i) = mis
       along_err(i) = mis
       pmin_p(i)  = mis
       vmax_p(i)  = mis
       DO j       = 1,ocount
        IF (itim_o(j).eq.itim_h(i)) THEN 
         pmin_err(i) = pmin_h(i) - pmin_o(j)
         vmax_err(i) = vmax_h(i) - vmax_o(j)
         lat_err(i)  = lat_h(i) - lat_o(j)
         lon_err(i)  = lon_h(i) - lon_o(j)
         trak_err(i) = sqrt(lat_err(i)**2. + lon_err(i)**2.)*111
         pmin_p(i)   = pmin_o(j)
         vmax_p(i)   = vmax_o(j)
         IF (i.gt.1.and.j.gt.1) THEN
          lato1      = lat_o(j-1)
          lono1      = lon_o(j-1)
          lato2      = lat_o(j)
          lono2      = lon_o(j)
          latf       = lat_h(i)
          lonf       = lon_h(i)
          CALL cross_along_err(lato1,lono1,lato2,lono2,latf,lonf,aerr,cerr)
          cross_err(i) = cerr
          along_err(i) = aerr     
         ENDIF
         WRITE(*,'(1I3,1I12,7F12.4)')i,itim_h(i),pmin_err(i), &
         vmax_err(i),lat_err(i),lon_err(i),trak_err(i),cross_err(i),along_err(i)
         GOTO 17
        ENDIF
       ENDDO
       PRINT*,'Fst time:',itim_h(i),' has no obs to validate'
17     CONTINUE
      ENDDO
!
! output the track file and intensity file
!
      OPEN(11,file='track_fst.dat')
      WRITE(11,*)'Forecast at',itim_h(1)
      WRITE(11,*)'0 0.1'
      WRITE(11,*)'10 1 9'
      WRITE(11,*)'0 3'
      DO i        = 1,hcount
       WRITE(11,'(I3,2F12.2)')(i-1)*dt,lon_h(i),lat_h(i)
      ENDDO
      CLOSE(11)
      OPEN(11,file='track_obs.dat')
      WRITE(11,*)'Observation '
      WRITE(11,*)'1 0.1'
      WRITE(11,*)'10 1 9'
      WRITE(11,*)'0 3'
      DO i        = 1,ocount
       WRITE(11,'(I3,2F12.2)')(i-1)*dt,lon_o(i),lat_o(i)
      ENDDO
      CLOSE(11)
      OPEN(11,file='grads.dat',form='UNFORMATTED',access='DIRECT',recl=nmax*4)
      WRITE(11,rec=irec)(pmin_h(i)*1.,i=1,nmax)
      irec        = irec + 1
      WRITE(11,rec=irec)(vmax_h(i)*1.,i=1,nmax)
      irec        = irec + 1
      WRITE(11,rec=irec)(pmin_p(i)*1.,i=1,nmax)
      irec        = irec + 1
      WRITE(11,rec=irec)(vmax_p(i)*1.,i=1,nmax)
      irec        = irec + 1
      WRITE(11,rec=irec)(trak_err(i),i=1,nmax)
      irec        = irec + 1
      WRITE(11,rec=irec)(along_err(i),i=1,nmax)
      irec        = irec + 1
      WRITE(11,rec=irec)(cross_err(i),i=1,nmax)
      irec        = irec + 1
      CLOSE(11)
      OPEN(11,file='fsct_error.dat')
      WRITE(11,'("Lead time",22F10.0)')(float(i-1)*dt,i=1,22)
      WRITE(11,'("Track err",22F10.2)')(trak_err(i),i=1,22)
      WRITE(11,'("Along err",22F10.2)')(along_err(i),i=1,22)
      WRITE(11,'("Cross err",22F10.2)')(cross_err(i),i=1,22)
      WRITE(11,'("Vmax  err",22F10.2)')(vmax_err(i),i=1,22)
      WRITE(11,'("Pmin  err",22F10.2)')(pmin_err(i),i=1,22)
      CLOSE(11)
      END

      SUBROUTINE input_file(ofile,lat_h,lon_h,pmin_h,vmax_h,itim_h,hcount,n,flag_filter)
      IMPLICIT NONE
      INTEGER n,hcount,flag_filter
      INTEGER pmin_h(n),vmax_h(n),itim_h(n)
      REAL lat_h(n),lon_h(n)
      INTEGER bdata,id(n),i,j,k,flen
      CHARACTER*100 ofile
      CHARACTER*164 tcvital
      CHARACTER*1 ns_index,we_index
      flen=len(ofile)
      OPEN(10,file=ofile(1:flen),status='old')
      hcount      = 1
11    CONTINUE
      READ(10,'(1A164)',end=12)tcvital
      READ(tcvital(49:51),'1I3')vmax_h(hcount)
      READ(tcvital(54:57),'1I4')pmin_h(hcount)
      READ(tcvital(36:38),'1F3.1')lat_h(hcount)
      READ(tcvital(42:45),'1F4.1')lon_h(hcount)      
      READ(tcvital(9:18),'1I10')itim_h(hcount)
      READ(tcvital(39:39),'1A1')ns_index
      READ(tcvital(46:46),'1A1')we_index
      IF (ns_index.eq.'S') lat_h(hcount)=-1*lat_h(hcount)
      IF (we_index.eq.'W') lon_h(hcount)=-1*lon_h(hcount)
      id(hcount)  = 1
      hcount      = hcount + 1
      GOTO 11
12    hcount      = hcount - 1
      CLOSE(10)
      PRINT*,'Number of data record is: ',hcount
!
! filter duplicate data if needed
!
      IF (flag_filter.ge.2) THEN
       PRINT*,'flag_filter=2 is not supported'
       DO i        = 1,hcount
        READ(10,*)itim_h(i)
       ENDDO
       STOP
      ENDIF
      IF (flag_filter.ge.1) THEN
       bdata       = 0
       DO i        = 1,hcount
        IF (id(i).eq.1) THEN
         DO j      = i+1,hcount
          IF (itim_h(j).eq.itim_h(i)) THEN
           id(j)   = 0
           bdata   = bdata + 1
          ENDIF
         ENDDO
        ENDIF
       ENDDO
       PRINT*,'Bad data is: ',bdata
       hcount      = hcount-bdata
       DO i        = 1,hcount
        DO j       = 1,hcount+bdata
         IF (id(j).eq.1) THEN
          itim_h(i)= itim_h(j)
          pmin_h(i)= pmin_h(j)
          vmax_h(i)= vmax_h(j)
          lat_h(i) = lat_h(j)
          lon_h(i) = lon_h(j)
          id(j)    = 0
          GOTO 21
         ENDIF
        ENDDO
21     CONTINUE
       ENDDO
      ENDIF
      RETURN
      END
   
      SUBROUTINE cross_along_err(lat1,lon1,lat2,lon2,lat3,lon3,aerr,cerr)
      IMPLICIT none
      REAL lat1,lon1,lat2,lon2,lat3,lon3,aerr,cerr
      REAL lats,lons,da,dc,a1,b1,a2,b2,check,total
!
! compute the mangitude of the along- and cross-the-track errors
!
      IF (lon2.eq.lon1) lon2 = lon1 + 1.e-5
      IF (lat2.eq.lat1) lat2 = lat1 + 1.e-5
      a1          = (lat2-lat1)/(lon2-lon1)
      b1          = lat1 - a1*lon1
      a2          = -(lon2-lon1)/(lat2-lat1)
      b2          = lat3 - a2*lon3
      lons        = (b2-b1)/(a1-a2)
      lats        = a1*lons + b1
      check       = a2*lon3 + b2
      da          = sqrt((lons-lon2)**2.+(lats-lat2)**2.)*111. ! km
      dc          = sqrt((lons-lon3)**2.+(lats-lat3)**2.)*111. ! km  
!      total       = sqrt((lon2-lon3)**2.+(lat2-lat3)**2.)*111. ! km
!      PRINT*,a1,b1,a2,b2
!      PRINT*,'=====>',lat1,lon1,lat2,lon2
!      PRINT*,lon3,lat3,check
!      PRINT*,lats,lons,da,dc,total
!      READ*
!
! assign a sign for the along-the-track error
!
      IF (lat2.gt.lat1) THEN
       IF (lats.gt.lat2) THEN
        aerr      = da
       ELSE
        aerr      = -1*da
       ENDIF
      ELSEIF (lat2.lt.lat1) THEN
       IF (lats.lt.lat2) THEN
        aerr      = da
       ELSE
        aerr      = -1*da
       ENDIF
      ELSE
       IF (lon2.lt.lon1) THEN
        IF (lons.lt.lon2) THEN
         aerr     = da
        ELSE
         aerr     = -1*da
        ENDIF 
       ELSE
        IF (lons.gt.lon2) THEN
         aerr     = da
        ELSE
         aerr     = -1*da
        ENDIF
       ENDIF
      ENDIF
!
! assign a sign for the cross-the-track error
!
      IF (lat2.gt.lat1) THEN
       IF (lons.lt.lon3) THEN
        cerr      = dc
       ELSE
        cerr      = -1*dc
       ENDIF
      ELSEIF (lat2.lt.lat1) THEN
       IF (lons.gt.lon3) THEN
        cerr      = dc
       ELSE
        cerr      = -1*dc
       ENDIF
      ELSE
       IF (lon2.lt.lon1) THEN
        IF (lats.lt.lat3) THEN
         cerr     = dc
        ELSE
         cerr     = -1*dc
        ENDIF
       ELSE
        IF (lats.gt.lat3) THEN
         cerr     = dc
        ELSE
         cerr     = -1*dc
        ENDIF
       ENDIF
      ENDIF
      RETURN
      END SUBROUTINE cross_along_err
      
