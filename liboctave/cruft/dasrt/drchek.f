      SUBROUTINE DRCHEK (JOB, G, NG, NEQ, TN, TOUT, Y, YP, PHI, PSI,
     *  KOLD, G0, G1, GX, JROOT, IRT, UROUND, INFO3, RWORK, IWORK,
     *  RPAR, IPAR)
C
C***BEGIN PROLOGUE  DRCHEK
C***REFER TO DDASRT
C***ROUTINES CALLED  DDATRP, DROOTS, DCOPY
C***DATE WRITTEN   821001   (YYMMDD)
C***REVISION DATE  900926   (YYMMDD)
C***END PROLOGUE  DRCHEK
C
      IMPLICIT DOUBLE PRECISION(A-H,O-Z)
      PARAMETER (LNGE=16, LIRFND=18, LLAST=19, LIMAX=20,
     *           LT0=41, LTLAST=42, LALPHR=43, LX2=44)
      EXTERNAL G
      INTEGER JOB, NG, NEQ, KOLD, JROOT, IRT, INFO3, IWORK, IPAR
      DOUBLE PRECISION TN, TOUT, Y, YP, PHI, PSI, G0, G1, GX, UROUND,
     *  RWORK, RPAR
      DIMENSION  Y(*), YP(*), PHI(NEQ,*), PSI(*),
     1  G0(*), G1(*), GX(*), JROOT(*), RWORK(*), IWORK(*)
      INTEGER I, JFLAG
      DOUBLE PRECISION H
      DOUBLE PRECISION HMING, T1, TEMP1, TEMP2, X
      LOGICAL ZROOT
C-----------------------------------------------------------------------
C THIS ROUTINE CHECKS FOR THE PRESENCE OF A ROOT IN THE
C VICINITY OF THE CURRENT T, IN A MANNER DEPENDING ON THE
C INPUT FLAG JOB.  IT CALLS SUBROUTINE DROOTS TO LOCATE THE ROOT
C AS PRECISELY AS POSSIBLE.
C
C IN ADDITION TO VARIABLES DESCRIBED PREVIOUSLY, DRCHEK
C USES THE FOLLOWING FOR COMMUNICATION..
C JOB    = INTEGER FLAG INDICATING TYPE OF CALL..
C          JOB = 1 MEANS THE PROBLEM IS BEING INITIALIZED, AND DRCHEK
C                  IS TO LOOK FOR A ROOT AT OR VERY NEAR THE INITIAL T.
C          JOB = 2 MEANS A CONTINUATION CALL TO THE SOLVER WAS JUST
C                  MADE, AND DRCHEK IS TO CHECK FOR A ROOT IN THE
C                  RELEVANT PART OF THE STEP LAST TAKEN.
C          JOB = 3 MEANS A SUCCESSFUL STEP WAS JUST TAKEN, AND DRCHEK
C                  IS TO LOOK FOR A ROOT IN THE INTERVAL OF THE STEP.
C G0     = ARRAY OF LENGTH NG, CONTAINING THE VALUE OF G AT T = T0.
C          G0 IS INPUT FOR JOB .GE. 2 AND ON OUTPUT IN ALL CASES.
C G1,GX  = ARRAYS OF LENGTH NG FOR WORK SPACE.
C IRT    = COMPLETION FLAG..
C          IRT = 0  MEANS NO ROOT WAS FOUND.
C          IRT = -1 MEANS JOB = 1 AND A ROOT WAS FOUND TOO NEAR TO T.
C          IRT = 1  MEANS A LEGITIMATE ROOT WAS FOUND (JOB = 2 OR 3).
C                   ON RETURN, T0 IS THE ROOT LOCATION, AND Y IS THE
C                   CORRESPONDING SOLUTION VECTOR.
C T0     = VALUE OF T AT ONE ENDPOINT OF INTERVAL OF INTEREST.  ONLY
C          ROOTS BEYOND T0 IN THE DIRECTION OF INTEGRATION ARE SOUGHT.
C          T0 IS INPUT IF JOB .GE. 2, AND OUTPUT IN ALL CASES.
C          T0 IS UPDATED BY DRCHEK, WHETHER A ROOT IS FOUND OR NOT.
C          STORED IN THE GLOBAL ARRAY RWORK.
C TLAST  = LAST VALUE OF T RETURNED BY THE SOLVER (INPUT ONLY).
C          STORED IN THE GLOBAL ARRAY RWORK.
C TOUT   = FINAL OUTPUT TIME FOR THE SOLVER.
C IRFND  = INPUT FLAG SHOWING WHETHER THE LAST STEP TAKEN HAD A ROOT.
C          IRFND = 1 IF IT DID, = 0 IF NOT.
C          STORED IN THE GLOBAL ARRAY IWORK.
C INFO3  = COPY OF INFO(3) (INPUT ONLY).
C-----------------------------------------------------------------------
C     
      H = PSI(1)
      IRT = 0
      DO 10 I = 1,NG
 10     JROOT(I) = 0
      HMING = (DABS(TN) + DABS(H))*UROUND*100.0D0
C
      GO TO (100, 200, 300), JOB
C
C EVALUATE G AT INITIAL T (STORED IN RWORK(LT0)), AND CHECK FOR
C ZERO VALUES.----------------------------------------------------------
 100  CONTINUE
      CALL DDATRP(TN,RWORK(LT0),Y,YP,NEQ,KOLD,PHI,PSI)
      CALL G (NEQ, RWORK(LT0), Y, NG, G0, RPAR, IPAR)
      IWORK(LNGE) = 1
      ZROOT = .FALSE.
      DO 110 I = 1,NG
 110    IF (DABS(G0(I)) .LE. 0.0D0) ZROOT = .TRUE.
      IF (.NOT. ZROOT) GO TO 190
C G HAS A ZERO AT T.  LOOK AT G AT T + (SMALL INCREMENT). --------------
      TEMP1 = DSIGN(HMING,H)
      RWORK(LT0) = RWORK(LT0) + TEMP1
      TEMP2 = TEMP1/H
      DO 120 I = 1,NEQ
 120    Y(I) = Y(I) + TEMP2*PHI(I,2)
      CALL G (NEQ, RWORK(LT0), Y, NG, G0, RPAR, IPAR)
      IWORK(LNGE) = IWORK(LNGE) + 1
      ZROOT = .FALSE.
      DO 130 I = 1,NG
 130    IF (DABS(G0(I)) .LE. 0.0D0) ZROOT = .TRUE.
      IF (.NOT. ZROOT) GO TO 190
C G HAS A ZERO AT T AND ALSO CLOSE TO T.  TAKE ERROR RETURN. -----------
      IRT = -1
      RETURN
C
 190  CONTINUE
      RETURN
C
C
 200  CONTINUE
      IF (IWORK(LIRFND) .EQ. 0) GO TO 260
C IF A ROOT WAS FOUND ON THE PREVIOUS STEP, EVALUATE G0 = G(T0). -------
      CALL DDATRP (TN, RWORK(LT0), Y, YP, NEQ, KOLD, PHI, PSI)
      CALL G (NEQ, RWORK(LT0), Y, NG, G0, RPAR, IPAR)
      IWORK(LNGE) = IWORK(LNGE) + 1
      ZROOT = .FALSE.
      DO 210 I = 1,NG
 210    IF (DABS(G0(I)) .LE. 0.0D0) ZROOT = .TRUE.
      IF (.NOT. ZROOT) GO TO 260
C G HAS A ZERO AT T0.  LOOK AT G AT T + (SMALL INCREMENT). -------------
      TEMP1 = DSIGN(HMING,H)
      RWORK(LT0) = RWORK(LT0) + TEMP1
      IF ((RWORK(LT0) - TN)*H .LT. 0.0D0) GO TO 230
      TEMP2 = TEMP1/H
      DO 220 I = 1,NEQ
 220    Y(I) = Y(I) + TEMP2*PHI(I,2)
      GO TO 240
 230  CALL DDATRP (TN, RWORK(LT0), Y, YP, NEQ, KOLD, PHI, PSI)
 240  CALL G (NEQ, RWORK(LT0), Y, NG, G0, RPAR, IPAR)
      IWORK(LNGE) = IWORK(LNGE) + 1
      ZROOT = .FALSE.
      DO 250 I = 1,NG
        IF (DABS(G0(I)) .GT. 0.0D0) GO TO 250
        JROOT(I) = 1
        ZROOT = .TRUE.
 250    CONTINUE
      IF (.NOT. ZROOT) GO TO 260
C G HAS A ZERO AT T0 AND ALSO CLOSE TO T0.  RETURN ROOT. ---------------
      IRT = 1
      RETURN
C     HERE, G0 DOES NOT HAVE A ROOT
C G0 HAS NO ZERO COMPONENTS.  PROCEED TO CHECK RELEVANT INTERVAL. ------
 260  IF (TN .EQ. RWORK(LTLAST)) GO TO 390
C
 300  CONTINUE
C SET T1 TO TN OR TOUT, WHICHEVER COMES FIRST, AND GET G AT T1. --------
      IF (INFO3 .EQ. 1) GO TO 310
      IF ((TOUT - TN)*H .GE. 0.0D0) GO TO 310
      T1 = TOUT
      IF ((T1 - RWORK(LT0))*H .LE. 0.0D0) GO TO 390
      CALL DDATRP (TN, T1, Y, YP, NEQ, KOLD, PHI, PSI)
      GO TO 330
 310  T1 = TN
      DO 320 I = 1,NEQ
 320    Y(I) = PHI(I,1)
 330  CALL G (NEQ, T1, Y, NG, G1, RPAR, IPAR)
      IWORK(LNGE) = IWORK(LNGE) + 1
C CALL DROOTS TO SEARCH FOR ROOT IN INTERVAL FROM T0 TO T1. ------------
      JFLAG = 0
 350  CONTINUE
      CALL DROOTS (NG, HMING, JFLAG, RWORK(LT0), T1, G0, G1, GX, X,
     *             JROOT, IWORK(LIMAX), IWORK(LLAST), RWORK(LALPHR),
     *             RWORK(LX2))
      IF (JFLAG .GT. 1) GO TO 360
      CALL DDATRP (TN, X, Y, YP, NEQ, KOLD, PHI, PSI)
      CALL G (NEQ, X, Y, NG, GX, RPAR, IPAR)
      IWORK(LNGE) = IWORK(LNGE) + 1
      GO TO 350
 360  RWORK(LT0) = X
      CALL DCOPY (NG, GX, 1, G0, 1)
      IF (JFLAG .EQ. 4) GO TO 390
C FOUND A ROOT.  INTERPOLATE TO X AND RETURN. --------------------------
      CALL DDATRP (TN, X, Y, YP, NEQ, KOLD, PHI, PSI)
      IRT = 1
      RETURN
C
 390  CONTINUE
      RETURN
C---------------------- END OF SUBROUTINE DRCHEK -----------------------
      END
