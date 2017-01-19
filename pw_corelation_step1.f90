      PROGRAM bias_tc_intensity
      IMPLICIT none
      INTEGER, PARAMETER :: n=10000                     ! max num of data length
      INTEGER, PARAMETER :: nbin=17                     ! number of intensity bin
      INTEGER            :: pmin_h(n)                   ! pmin-hwrf forecast
      INTEGER            :: vmax_h(n)                   ! vmax-hwrf forecast
      INTEGER            :: itim_h1(n)                  ! hwrf forecast initial time
      INTEGER            :: itim_h2(n)                  ! hwrf forecast time
      INTEGER            :: pmin_o(n)                   ! pmin obs
      INTEGER            :: vmax_o(n)                   ! vmax obs
      INTEGER            :: itim_o(n)                   ! obs time
      INTEGER            :: pmin_b(n)                   ! pmin-hwrf ini time
      INTEGER            :: vmax_b(n)                   ! vmax-hwrf ini time
      INTEGER            :: itim_b(n)                   ! hwrf initial cycle
      REAL               :: pmin_err(n)                 ! pmin error for each cycle
      REAL               :: vmax_err(n)                 ! vmax error for each cycle
      REAL               :: pmin_erb(n)                 ! pmin error for each bin
      REAL               :: vmax_erb(n)                 ! vmax error for each bin
      INTEGER            :: hcount                      ! number of hwrf forecast
      INTEGER            :: ocount                      ! number of obs time
      INTEGER            :: bcount                      ! number of hwrf initial cycle
      INTEGER            :: nmatch                      ! dump var
      INTEGER            :: i,j,k,m                     ! dump var
      INTEGER            :: bin_min(nbin),bin_max(nbin) ! bin sup and inf 
      INTEGER            :: bin_count(nbin)             ! number of cycles in each bin 
      INTEGER            :: bin_index(nbin,n)           ! index of cycles in each bin
      CHARACTER*100      :: ofile1,ofile2,ofile3        ! dump var
!
! define intensity bin. 
!
      bin_min = (/15,20,25,30,35,40,45,50,55,60,65,70,80,90,100,120,130/)
      bin_max = (/20,25,30,35,40,45,50,55,60,65,70,80,90,100,120,130,300/)
      PRINT*,'Enter input files'
      READ*,ofile1
      READ*,ofile2
      READ*,ofile3
!
! reading the HWRF forecast first
!
      CALL input_file2(ofile1,pmin_h,vmax_h,itim_h1,itim_h2,hcount,n)
      PRINT*,'Number of HWRF data forecast record is: ',hcount
!
! reading observation
!
      CALL input_file(ofile2,pmin_o,vmax_o,itim_o,ocount,n)
      PRINT*,'Number of OBS data record is: ',ocount
!
! reading the HWRF initialization for the bin
!
      CALL input_file(ofile3,pmin_b,vmax_b,itim_b,bcount,n)
      PRINT*,'Number of HWRF initial data record is: ',bcount
      IF (hcount.gt.bcount) THEN
       PRINT*,'WARNING: Forecasts are larger than inititalization :-('
      ELSEIF (hcount.lt.bcount) THEN
       PRINT*,'WARNING: some forecasts may have not lasted 6 hours :-('
      ENDIF
!
! compute next the tendency of the HWRF forecast valid for each initial time
!
      DO i        = 1,hcount
       pmin_err(i)= 0
       vmax_err(i)= 0
       DO j       = 1,bcount
        IF (itim_b(j).eq.itim_h1(i)) THEN 
         pmin_err(i) = pmin_h(i) - pmin_b(j)
         vmax_err(i) = vmax_h(i) - vmax_b(j)
         PRINT*,'Match at :',i,j,itim_h1(i)
         PRINT*,pmin_h(i),pmin_b(j),pmin_err(i)
         PRINT*,vmax_h(i),vmax_b(j),vmax_err(i)
         PRINT*,'============================='
         GOTO 17
        ENDIF
       ENDDO
       PRINT*,'Fst time:',itim_h1(i),' has no corresponding ini ? stop'
       STOP
17     CONTINUE
      ENDDO
!
! catergory the initialization into bin and compute error for
! each bin
!
      OPEN(11,file='out.txt')
      WRITE(11,*)'bin       vmax       pmin      num'
      DO i        = 1,nbin
       k          = 0
       DO j       = 1,bcount
        IF (bin_min(i).le.vmax_b(j).and.vmax_b(j).lt.bin_max(i)) THEN
         k        = k + 1
         bin_index(i,k) = j
        ENDIF
       ENDDO 
       bin_count(i)  = k
!
! compute mean error within each bin
!
       pmin_erb(i)= 0
       vmax_erb(i)= 0
       nmatch     = 0 
       DO j       = 1,bin_count(i)
        m         = bin_index(i,j)
        DO k      = 1,hcount
         IF (itim_h1(k).eq.itim_b(m)) THEN
          pmin_erb(i)= pmin_erb(i)+ pmin_err(k)
          vmax_erb(i)= vmax_erb(i)+ vmax_err(k)
          nmatch  = nmatch + 1
         ENDIF
        ENDDO
       ENDDO 
       IF (nmatch.ne.0) THEN
        pmin_erb(i)= real(pmin_erb(i))/real(nmatch)
        vmax_erb(i)= real(vmax_erb(i))/real(nmatch)
        PRINT*,'BIN error is: ',i,nmatch,bin_count(i)
        PRINT*,'    pmin err is :',pmin_erb(i)
        PRINT*,'    vmax err is :',vmax_erb(i)
        WRITE(11,'(I3,2F12.4,I8)'),i,vmax_erb(i),pmin_erb(i),nmatch
       ELSE
        PRINT*,'BIN ',i,' is empty' 
        WRITE(11,'(I3,2F12.4,I8)'),i,-9999.,-9999.,0
       ENDIF
      ENDDO
      END

      SUBROUTINE input_file(ofile,pmin_h,vmax_h,itim_h,hcount,n)
      IMPLICIT NONE
      INTEGER n,hcount
      INTEGER pmin_h(n),vmax_h(n),itim_h(n)
      INTEGER bdata,id(n),i,j,k,flen
      CHARACTER*100 ofile
      CHARACTER*164 tcvital
      flen=len(ofile)
      OPEN(10,file=ofile(1:flen),status='old')
      hcount      = 1
11    CONTINUE
      READ(10,'(1A164)',end=12)tcvital
      READ(tcvital(49:51),'(1I3)')vmax_h(hcount)
      READ(tcvital(54:57),'(1I4)')pmin_h(hcount)
      READ(tcvital(9:18),'(1I10)')itim_h(hcount)
      id(hcount)  = 1
      hcount      = hcount + 1
      GOTO 11
12    hcount      = hcount - 1
      CLOSE(10)
      PRINT*,'Number of data record is: ',hcount
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
!       PRINT*,i,itim_h(i),id(i),bdata
      ENDDO
      PRINT*,'Bad data is: ',bdata
      hcount      = hcount-bdata
      DO i        = 1,hcount
       DO j       = 1,hcount+bdata
        IF (id(j).eq.1) THEN
         itim_h(i)= itim_h(j)
         pmin_h(i)= pmin_h(j)
         vmax_h(i)= vmax_h(j)
         id(j)    = 0
         GOTO 21
        ENDIF
       ENDDO
21     CONTINUE
!       PRINT*,i,itim_h(i)
      ENDDO
      RETURN
      END

      SUBROUTINE input_file2(ofile,pmin_h,vmax_h,itim_h1,itim_h2,hcount,n)
      IMPLICIT NONE
      INTEGER n,hcount
      INTEGER pmin_h(n),vmax_h(n),itim_h1(n),itim_h2(n)
      INTEGER bdata,id(n),i,j,k,flen
      CHARACTER*100 ofile
      CHARACTER*164 tcvital
      flen=len(ofile)
      OPEN(10,file=ofile(1:flen),status='old')
      hcount      = 1
11    CONTINUE
      READ(10,'(1A164)',end=12)tcvital
      READ(tcvital(49:51),'(1I3)')vmax_h(hcount)
      READ(tcvital(54:57),'(1I4)')pmin_h(hcount)
      READ(tcvital(9:18),'(1I10)')itim_h1(hcount)
      READ(tcvital(98:107),'(1I10)')itim_h2(hcount)
      id(hcount)  = 1
      hcount      = hcount + 1
      GOTO 11
12    hcount      = hcount - 1
      CLOSE(10)
      PRINT*,'Number of data record is: ',hcount
      bdata       = 0
      DO i        = 1,hcount
       IF (id(i).eq.1) THEN
        DO j      = i+1,hcount
         IF (itim_h1(j).eq.itim_h1(i)) THEN
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
         itim_h1(i)= itim_h1(j)
         itim_h2(i)= itim_h2(j)
         pmin_h(i)= pmin_h(j)
         vmax_h(i)= vmax_h(j)
         id(j)    = 0
         GOTO 21
        ENDIF
       ENDDO
21     CONTINUE
      ENDDO
      RETURN
      END


      
