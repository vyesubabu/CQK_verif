      PROGRAM compute_error_mean
      IMPLICIT none
      INTEGER, PARAMETER :: nt=100,nm=100000
      REAL               :: vmax(nt,nm),pmin(nt,nm),trak(nt,nm)
      REAL               :: vmax_gd(nt),pmin_gd(nt),trak_gd(nt)
      REAL               :: vmax_all(nt),pmin_all(nt),trak_all(nt)
      REAL               :: sum1,sum2,sum3,mis
      REAL               :: gtrack_1d, gtrack_2d, gtrack_3d
      INTEGER            :: i,j,k,ncount,nrow,ncol
      CHARACTER*100      :: ifile,tem
      INTEGER            :: np1(nt),np2(nt),nv1(nt)
      INTEGER            :: nv2(nt),nt1(nt),nt2(nt)
      PRINT*,'Enter good track threshold for 1,2,3 day'
      READ*,gtrack_1d,gtrack_2d,gtrack_3d
      PRINT*,"Enter the input error statistics file"
      READ*,ifile
      ncol         = 22   ! number of forecast lead time
      ncount       = len_trim(ifile)
      mis          = -99999
      OPEN(10,file=ifile(1:ncount),status='old')
!
! reading data input
!
      ncount       = 1
10    CONTINUE
      READ(10,*,end=11)
      READ(10,*,end=11)tem,tem,(trak(i,ncount),i=1,ncol)
      READ(10,*,end=11)
      READ(10,*,end=11)
      READ(10,*,end=11)tem,tem,(vmax(i,ncount),i=1,ncol)
      READ(10,*,end=11)tem,tem,(pmin(i,ncount),i=1,ncol)
      PRINT*,ncount,trak(1,ncount),vmax(1,ncount),pmin(1,ncount)
      ncount       = ncount + 1
      GOTO 10
11    nrow         = ncount - 1
      PRINT*,'Get number of data rows is: ',nrow 
!
! compute the entire mean of track and intensity
!      
      DO i         = 1,ncol
! track
       sum1        = 0.
       ncount      = 0
       DO j        = 1,nrow
        IF (trak(i,j).ne.mis) THEN
         sum1      = sum1 + trak(i,j)
         ncount    = ncount + 1
        ENDIF
       ENDDO 
       IF (ncount.gt.0) THEN
        trak_all(i)= sum1/ncount   
       ELSE
        trak_all(i)= mis
       ENDIF   
       nt1(i)      = ncount
! vmax
       sum1        = 0.
       ncount      = 0
       DO j        = 1,nrow
        IF (vmax(i,j).ne.mis) THEN
         sum1      = sum1 + abs(vmax(i,j))
         ncount    = ncount + 1
        ENDIF
       ENDDO
       IF (ncount.gt.0) THEN
        vmax_all(i)= sum1/ncount
       ELSE
        vmax_all(i)= mis
       ENDIF
       np1(i)      = ncount
! pmin
       sum1        = 0.
       ncount      = 0
       DO j        = 1,nrow
        IF (pmin(i,j).ne.mis) THEN
         sum1      = sum1 + abs(pmin(i,j))
         ncount    = ncount + 1
        ENDIF
       ENDDO
       IF (ncount.gt.0) THEN
        pmin_all(i)= sum1/ncount
       ELSE
        pmin_all(i)= mis
       ENDIF
       nv1(i)      = ncount
      ENDDO
!
! compute the mean of intensity for good track only.
!      
      DO i         = 1,ncol
! pmin
       sum1        = 0.
       ncount      = 0
       DO j        = 1,nrow
        IF (pmin(i,j).ne.mis.and.abs(trak(5,j)).lt.gtrack_1d.and. & 
            abs(trak(9,j)).lt.gtrack_2d.and.abs(trak(13,j)).lt.gtrack_3d) THEN
         sum1      = sum1 + abs(pmin(i,j))
         ncount    = ncount + 1
        ENDIF
       ENDDO
       IF (ncount.gt.0) THEN
        pmin_gd(i)= sum1/ncount
       ELSE
        pmin_gd(i)= mis
       ENDIF
       np2(i)     = ncount
! vmax
       sum1        = 0.
       ncount      = 0
       DO j        = 1,nrow
        IF (pmin(i,j).ne.mis.and.abs(trak(5,j)).lt.gtrack_1d.and. & 
            abs(trak(9,j)).lt.gtrack_2d.and.abs(trak(13,j)).lt.gtrack_3d) THEN
         sum1      = sum1 + abs(vmax(i,j))
         ncount    = ncount + 1
        ENDIF
       ENDDO
       IF (ncount.gt.0) THEN
        vmax_gd(i)= sum1/ncount
       ELSE
        vmax_gd(i)= mis
       ENDIF
       nv2(i)     = ncount
! track
       sum1        = 0.
       ncount      = 0
       DO j        = 1,nrow
        IF (pmin(i,j).ne.mis.and.abs(trak(5,j)).lt.gtrack_1d.and. & 
            abs(trak(9,j)).lt.gtrack_2d.and.abs(trak(13,j)).lt.gtrack_3d) THEN
         sum1      = sum1 + trak(i,j)
         ncount    = ncount + 1
         PRINT*,i,j,trak(i,j),abs(trak(13,j))
        ENDIF
       ENDDO
       IF (ncount.gt.0) THEN
        trak_gd(i)= sum1/ncount
       ELSE
        trak_gd(i)= mis
       ENDIF
       nt2(i)     = ncount
      ENDDO
!
! open output file
!
      OPEN(11,file='statistics_model.dat')
      WRITE(11,'(1A10,12A11)')"Time","Track_all","Ncase_trk","Vmax_all","Ncase_vmx",      &
                              "Pmin_all","Ncase_pmn","Track_good","Ncase_gtrk",           &
                              "Vmax_good","Ncase_vmxg","Pmin_good","Ncase_pmng"
      DO i        = 1,ncol 
       WRITE(11,'(1I10,6(1F11.2,1I11))')(i-1)*6,trak_all(i),nt1(i),vmax_all(i),nv1(i),    &
                                         pmin_all(i),np1(i),trak_gd(i),nt2(i),vmax_gd(i), &
                                         nv2(i),pmin_gd(i),np2(i)
      ENDDO
      END
