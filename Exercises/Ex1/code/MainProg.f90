PROGRAM diffusivity_solver

  REAL :: DT

  DT = 0.0025

  CALL IMPLICIT(DT)
  CALL ANALYTICAL(DT)

END PROGRAM diffusivity_solver




SUBROUTINE TRIDIA(N,A,B,C,D,P)
!------------------------------------------------------------------
!     THE SUBROUTINE USES GAUSSIAN ELIMINATION FOR SOLUTION OF THE
!     SET OF EQUATIONS
!   
!     A(I)*P(I-1) + B(I)*P(I) + C(I)*P(I+1) = D(I)
!
!     A(I),B(I),C(I),D(I)=MATRIX COEFFICIENTS
!     P=UNKNOWN PRESSURE
!     N=NUMBER OF EQUATIONS
!------------------------------------------------------------------  
   REAL X
   REAL A(25),B(25),C(25),D(25),P(25),BB(25),DD(25)
   INTEGER I,K,N
   BB(1)=B(1)
   DD(1)=D(1)
   DO I=2,N
      X=A(I)/BB(I-1)
      BB(I)=B(I)-X*C(I-1)
      DD(I)=D(I)-X*DD(I-1)
   END DO

   P(N)=DD(N)/BB(N)

   DO K=2,N
      I=N-K+1
      P(I)=(DD(I)-C(I)*P(I+1))/BB(I)
   END DO    
END SUBROUTINE TRIDIA





!-----------------------------------------------------------------------
!     FINITE DIFFERENCE SOLUTION OF ONE-PHASE DIFFUSIVITY EQUATION
!     FOR CONSTANT LEFT SIDE AND RIGHT SIDE PRESSURES (PL AND PR)
!
!     P AND PNEW = PRESSURES
!     POR = POROSITY
!     PERM = PERMEABILITY
!     VISC = VISCOSITY
!     COMPR = COMPRESSIBILITY
!     L = LENGTH
!     PINIT= INITIAL PRESSURE
!     PL = LEFT SIDE PRESSURE
!     PR = RIGHT SIDE PRESSURE
!     DT = TIME STEP SIZE
!     TMAX = MAX TIME OF SIMULATION
!     N = NUMBER OF GRID BLOCKS
!     IPRINT = NUMBER OF TIME STEPS BETWEEN PRINTOUTS
!-----------------------------------------------------------------------

SUBROUTINE IMPLICIT(DT)
   REAL, INTENT(IN) :: DT    
   REAL P(25),PNEW(25),X(25),A(25),B(25),C(25),D(25)
   REAL POR,PERM,VISC,COMPR,L,PL,PR,PINIT,TMAX,PI,DX
   INTEGER I,J,K,N
   CHARACTER(LEN=30) :: FILENAME
   CHARACTER(LEN=10) :: DT_STRING

   DATA POR/0.2/,PERM/1.0/,VISC/1.0/,COMPR/0.0001/,L/100./,PL/2.0/ &
   ,PR/1.0/PINIT/1.0/,N/10/,TMAX/0.2/,IPRINT/1/
   DATA PI/3.14159/

   WRITE(DT_STRING, '(I8)') INT((DT*1000000.0))
   FILENAME = ADJUSTL(TRIM(DT_STRING)//ADJUSTL('µs_IMP.dat'))

   DX=L/N
   T=0.
   CONST=DT/DX/DX*PERM/POR/VISC/COMPR
   ALPHA=1./CONST
   ISW=0
   DO I=1,N
      P(I)=PINIT
      PNEW(I)=PINIT
      X(I)=L*I/N-L/N/2.
   END DO
    
   !OPEN OUTPUT FILE
   OPEN(10,FILE=FILENAME,STATUS='UNKNOWN')

   !TIME LOOP
   DO J=1,1000
      ISW=ISW+1
      T=T+DT

      !COEFFICIENTS FOR BLOCK 1
      A(1)=0.
      B(1)=-3.-ALPHA
      C(1)=1.
      D(1)=-ALPHA*P(1)-2.*PL

      !COEFFICIENTS FOR BLOCKS 2 TO N-1
      DO I=2,N-1
         A(I)=1.
         B(I)=-2.-ALPHA
         C(I)=1.
         D(I)=-ALPHA*P(I)
      END DO

      !COEFFICIENTS FOR BLOCK N
      A(N)=1.
      B(N)=-3.-ALPHA
      C(N)=0.
      D(N)=-ALPHA*P(N)-2.*PR

      !GET NEW PRESSURES BY CALLING GAUSSIAN ELIMINATION ROUTINE
      CALL TRIDIA(N,A,B,C,D,PNEW)

      !PRINT (?)
      IF(ISW.EQ.IPRINT) THEN
         ISW=0
         WRITE(10,100)T,PL,(PNEW(I),I=1,N),PR
         100 FORMAT(50F10.4)
      END IF

      !END (?)
      IF(T.GE.TMAX)RETURN

      !UPDATING OF PRESSURES
      DO I=1,N
         P(I)=PNEW(I)
      END DO
   END DO
END SUBROUTINE IMPLICIT



SUBROUTINE ANALYTICAL(DT)
   REAL, INTENT(IN) :: DT
   REAL P(25),PNEW(25),X(25),A(25),B(25),C(25),D(25)
   REAL POR,PERM,VISC,COMPR,L,PL,PR,PINIT,TMAX,PI,DX
   INTEGER I,J,K,ISW,N
   CHARACTER(LEN=30) :: FILENAME
   CHARACTER(LEN=10) :: DT_STRING

   POR=0.2
   PERM=1.0
   VISC=1.0
   COMPR=0.0001
   L=100
   PL=2.0
   PR=1.0
   PINIT=1.0
   N=10
   TMAX=0.2
   IPRINT=1
   PI=3.14159

   DX=L/N
   T=0.
   CONST=DT/DX/DX*PERM/POR/VISC/COMPR
   ALPHA=1./CONST
   ISW=0

   WRITE(DT_STRING, '(I8)') INT((DT*1000000.0))
   FILENAME = ADJUSTL(TRIM(DT_STRING)//ADJUSTL('µs_ANL.dat'))

   DO I=1,N
     P(I)=PINIT
     PNEW(I)=PINIT
     X(I)=L*I/N-L/N/2.
   END DO


   ! OPEN OUTPUT FILE
   OPEN(10,FILE=FILENAME,STATUS='UNKNOWN')


   ! TIME LOOP
   DO J=1,1000
     ISW=ISW+1
     T=T+DT

     ! ANALYTICAL SOLUTION
     DO I=1,N
       PNEW(I)=PL+(PR-PL)*X(I)/L
       DO K=1,1000
         DP=(PR-PL)*2./PI/K*EXP(-PI*PI*K*K/L/L*PERM*T/POR/VISC/COMPR) &
         *SIN(X(I)*K*PI/L)
         PNEW(I)=PNEW(I)+DP
         IF(K.GT.10.AND.ABS(DP).LT.0.0000001) EXIT
       END DO ! end inner analytical sol. loop
     END DO ! end outer analytical sol. loop     

     ! PRINT (?)
     IF(ISW.EQ.IPRINT) THEN
       ISW=0
       WRITE(10,100)T,PL,(PNEW(I),I=1,N),PR
       100 FORMAT(50F10.4)
     END IF ! end print if

     ! END (?)
     IF(T.GE.TMAX)RETURN

     ! UPDATING OF PRESSURES
     DO I=1,N
       P(I)=PNEW(I)
     END DO ! end updating pressure loop

   END DO ! end time loop
END SUBROUTINE ANALYTICAL