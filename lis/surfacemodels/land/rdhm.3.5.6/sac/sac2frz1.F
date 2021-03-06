C  SUBROUTINE SPLITS FREE AND TENSION WATER STORAGES OF SAC-SMA
C  INTO TOTAL WATER CONTENTS OF FROZEN GROUND MODEL SOIL LAYERS
CVK 12/2005  Added parameter SWLT to the subroutine parameters

CVK  12/2005      SUBROUTINE SAC2FRZ1(DWT,DWF,SMC,SH2O,NUPL,NLOWL,ZSOIL,SMAX)
      SUBROUTINE SAC2FRZ1(DWT,DWF,SMC,SH2O,NUPL,NLOWL,ZSOIL,SMAX,SWLT)
#include "config.h"
     
C   DWT - TENSION WATER CHANGE PER TIME INTERVAL, MM
C   DWF - FREE WATER CHANGE PER TIME INTERVAL, MM
C   SMC - TOTAL MOISTURE CONTENT OF FROZEN GROUND MODEL LAYERS
C   SH2O - UNFROZEN WATER CONTENT OF FROZEN GROUND MODEL LAYERS
C   NUPL - UPPER SOIL LAYER TO DISTRIBUTE SAC-SMA WATER
C   NLOWL - LOWER SOIL LAYER TO DISTRIBUTE SAC-SMA WATER
C   ZSOIL - SOIL LAYER DEPTHS, M
C   SMAX - SOIL POROSITY

      REAL ZSOIL(*),SMC(*),SH2O(*)
      INTEGER MS(10)

C  SPLIT FREE WATER BETWEEN SOIL LAYERS
C  FREE WATER IS SPLITTED EQUALLY RETWEEN LAYERS 
      if(nupl .gt. 5) then
       write(*,*) 'nup',nupl,nlowl,dwt,dwf,(zsoil(i),i=1,5)
       stop
      endif 
      DO I=NUPL,NLOWL
       MS(I)=1
      ENDDO 
      Z=ZSOIL(NUPL-1)-ZSOIL(NLOWL)
      DSF=0.001*DWF/Z
      M=0
100   NN=0
      M=M+1
      IF(M .LE. NLOWL-NUPL+1) THEN
       DWX=0.
       IF(M .GT. 1) THEN
        Z=0.
        DO II=NUPL,NLOWL
         Z=Z+(ZSOIL(II-1)-ZSOIL(II))*MS(II)
        ENDDO
       ENDIF  
       DO I=NUPL,NLOWL
        IF(MS(I) .NE. 0) THEN
         SMC(I)=SMC(I)+DSF          
         SH2O(I)=SH2O(I)+DSF
         DELTA=SMC(I)-SMAX
CVK  12/2005       IF(DELTA .GT. 0.0001 .OR. SMC(I) .LT. 0.) THEN
         IF(DELTA .GT. 0.0000001 .OR. SMC(I) .LT. SWLT) THEN
          NN=I
          MS(I)=0
          DZ=ZSOIL(I-1)-ZSOIL(I)
          Z=Z-DZ
CVK  12/2005        IF(SMC(I) .GE. 0.) THEN
          IF(SMC(I) .GE. SWLT) THEN
           DWX=DWX+DELTA*DZ*1000.
           SH2O(I)=SH2O(I)-DELTA
           SMC(I)=SMAX
          ELSE
c03/10  wrong statement:   DWX=DWX+SMC(I)*DZ*1000.
c03/10  replaced with the next one
           DWX=DWX+(SMC(I)-SWLT)*DZ*1000.
C           DWX=DWX+SMC(I)*DZ*1000.
CVK  12/2005         SMC(I)=0.
CVK  12/2005         SH2O(I)=0.
           SMC(I)=SWLT
           SH2O(I)=SWLT              
          ENDIF
         ENDIF 
        ENDIF
       ENDDO

       IF(NN .NE. 0 .AND. Z .GT. 0.0001) THEN
        DSF=0.001*DWX/Z
        GOTO 100
       ENDIF 
      ELSE
#ifdef ENABLE_DEBUGINFO
       WRITE(*,*) ' WARN: NO BALANCE IN SAC2FRZ',M,NUPL,NLOWL,DSF,
     +       DWF,NN,(MS(I),ZSOIL(I),SMC(I),I=NUPL,NLOWL)
       WRITE(*,*) ' WARN: NO BALANCE IN SAC2FRZ',M,NLOWL,DSF,DWF,DWX
#endif
      ENDIF 

C  SPLIT TENSION WATER: IF TENSION WATER REDUCTION, SPLIT BY A RATIO
C  OF UNFROZEN WATER FROM PREVIOUS TIME STEP; IF TENSION WATER INCREASE,
C  SPLIT BY AN INVERSE RATIO OF TOTAL WATER DEFICIT.
C
C  CALCULATE A RATIO OF UNFROZEN WATER OR RATIO OF TOTAL WATER DEFICIT
      N=1
77    SAVG=0.
      DO I=NUPL,NLOWL
       IF(DWT .LT. 0.) THEN
CVK  12/2005        SAVG=SAVG+SH2O(I)
        SAVG=SAVG+(SH2O(I)-SWLT)
       ELSE
        SAVG=SAVG+(SMAX-SMC(I))
       ENDIF   
      ENDDO
      SAVG=SAVG/(NLOWL-NUPL+1)
CVK  12/2005    IF(SAVG .LT. 1E-5) GOTO 7
      IF(SAVG .LT. 1E-6) GOTO 7
      
      ALP=0.
      DO I=NUPL,NLOWL
      DZ=ZSOIL(I-1)-ZSOIL(I)
       IF(DWT .LT. 0.) THEN
C  UNFROZEN WATER RATIO
CVK  12/2005         ALP=ALP+DZ*SH2O(I)/SAVG
        ALP=ALP+DZ*(SH2O(I)-SWLT)/SAVG
       ELSE
C  TOTAL WATER DEFICIT RATIO
        ALP=ALP+DZ*(SMAX-SMC(I))/SAVG
       ENDIF
      ENDDO
      ALP=1./ALP

C  RUN REDISTRIBUTION OF WATER BETWEEN SOIL LAYERS
      DDTX=0.
      DO I=NUPL,NLOWL
       DZ=ZSOIL(I-1)-ZSOIL(I)
       IF(DWT .LT. 0.) THEN
C  REDUCTION IN TENSION WATER. USE A RATIO OF UNFROZEN WATER
CVK  12/2005      DMAX=1000.*SH2O(I)*DZ
        DMAX=1000.*(SH2O(I)-SWLT)*DZ
CVK  12/2005        DZTX=DZ*(DWT*(SH2O(I)/SAVG)*ALP+
        DZTX=DZ*(DWT*((SH2O(I)-SWLT)/SAVG)*ALP+ 
     +       DDTX/(ZSOIL(I-1)-ZSOIL(NLOWL)))
        xx1=ABS(DZTX)
        IF(xx1 .GT. DMAX) THEN
         DDTX=DZTX+DMAX
         DZTX=-DMAX
        ENDIF 
       ELSE
C  INCREASE IN TENSION WATER. USE AN INVERSE RATIO OF UNFROZEN WATER
        DMAX=1000.*(SMAX-SMC(I))*DZ
        DZTX=DZ*(DWT*((SMAX-SMC(I))/SAVG)*ALP+
     +       DDTX/(ZSOIL(I-1)-ZSOIL(NLOWL)))       
        IF(DZTX .GT. DMAX) THEN
         DDTX=DZTX-DMAX
         DZTX=DMAX
        ENDIF 
       ENDIF
       
       A=0.001*DZTX/DZ
       SH2O(I)=SH2O(I)+A
       SMC(I)=SMC(I)+A
CVK  12/2005     IF(SH2O(I) .LT. 0.) SH2O(I)=0.
CVK  12/2005     IF(SMC(I) .LT. 0.) SMC(I)=0.
       IF(SH2O(I) .LT. SWLT) SH2O(I)=SWLT
       IF(SMC(I) .LT. SWLT) THEN
        SMC(I)=SWLT
        SH2O(I)=SWLT
       ENDIF 
      ENDDO

      xx1=ABS(DDTX)
CVK  12/2005    IF(xx1 .GT. 1E-2) THEN
      IF(xx1 .GT. 1E-4) THEN
       DWT=DDTX
       N=N+1
       IF(N .GT. 2) THEN
#ifdef ENABLE_DEBUGINFO
        WRITE(*,*) ' WARN: NO BALANCE IN SAC-SMA WATER CHANGE.'
#endif
       ELSE
        GOTO 77
       ENDIF 
      ENDIF 
      RETURN

7     CONTINUE
      RETURN      
      END
                                                        
