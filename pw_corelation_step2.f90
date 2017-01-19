      PROGRAM combine_bias
      IMPLICIT NONE
      INTEGER, PARAMETER :: nbin=17,nx=100
      REAL               :: vmax(nbin,nx),pmin(nbin,nx)
      INTEGER            :: i,j,k,nfile,ncase(nbin,nx)
      INTEGER            :: sum3,n1,n2
      REAL               :: mis,sum1,sum2
      CHARACTER*100      :: infile
      mis          = -9999.
      PRINT*,'How many storms do you have?'
      read*,nfile
!
! reading data
!
      infile       = 'out_0'
      DO i         = 1,nfile
       IF (i.lt.10) THEN
        WRITE(infile(5:5),'(1I1)')i
       ELSE
        WRITE(infile(5:6),'(1I2)')i
       ENDIF
       k           = len_trim(infile)
       OPEN(10,file=infile(1:k)//'.txt')
       READ(10,*)
       DO j        = 1,nbin
        READ(10,*)k,vmax(j,i),pmin(j,i),ncase(j,i)
        PRINT*,infile(1:8),j,vmax(j,i),pmin(j,i),ncase(j,i)
       ENDDO    
       CLOSE(10)
      ENDDO
!
! do the combination
!
      OPEN(11,file='pw_out.txt')
      WRITE(11,*)'bin       vmax       pmin      num'
      DO i         = 1,nbin
       sum1        = 0
       sum2        = 0
       sum3        = 0
       n1          = 0
       n2          = 0
       DO j        = 1,nfile
        IF (vmax(i,j).ne.mis) THEN
         sum1      = sum1 + vmax(i,j)
         n1        = n1 + 1
        ENDIF
        IF (pmin(i,j).ne.mis) THEN
         sum2      = sum2 + pmin(i,j)
         n2        = n2 + 1
        ENDIF
        sum3       = sum3 + ncase(i,j)
       ENDDO
       IF (n1.ne.0) sum1 = sum1/n1
       IF (n2.ne.0) sum2 = sum2/n2
       WRITE(11,'(I3,2F12.4,I8)'),i,sum1,sum2,sum3
      ENDDO
      END
