program cratersQ_equilbr
!***********************************************************************
!   cratersQ_equilbr: program to calculate surface energy balance
!             for constant sun position; equilibrium solution
!
!             zero thermal inertia, no orbit
!***********************************************************************
  use filemanager
  use allinterfaces
  use newhorizons
  implicit none
  real(8), parameter :: pi=3.1415926535897932, d2r=pi/180.
  real(8), parameter :: sigSB = 5.6704e-8  

  integer n, i, j, k, CCMAX, iii, jjj
  real(8), dimension(NSx,NSy) :: h, surfaceSlope, azFac
  real(8), dimension(NSx,NSy) :: Qn, QIR, Qrefl, QIRre   ! incoming
  real(8) R, azSun, smax, emiss, betaSun, Qshadow1, Qshadow2
  integer, dimension(NSx,NSy) :: cc
  integer(2), dimension(:,:,:), allocatable :: ii,jj
  real(8), dimension(NSx,NSy) :: Tsurf, Qvis, viewsize, Qabs, albedo, QIRin
  real(4), dimension(:,:,:), allocatable :: VF
  
  ! azimuth in degrees east of north, 0=north facing
  albedo(:,:) = 0.12
  emiss = 0.95

  R=1.
  azSun = 180.*d2r
  betaSun = 10.*d2r

  call readdem(h)
  call difftopo(NSx,NSy,h,dx,dy,surfaceSlope,azFac)

  print *,'...reading horizons file...'
  call readhorizons

  print *,'...reading huge viewfactors file...'
  CCMAX = getmaxfieldsize(NSx,NSy,vfn)
  print *,'... max field of view size=',CCMAX
  allocate(ii(NSx,NSy,CCMAX), jj(NSx,NSy,CCMAX), VF(NSx,NSy,CCMAX))
  !call getfieldofview(NSx,NSy,ffn,cc,ii,jj,dO12,landsize,CCMAX)
  call getviewfactors(NSx,NSy,vfn,cc,ii,jj,VF,viewsize,CCMAX)

  print *,'...calculating...'  
  print *,'beta=',betaSun/d2r,'azSun=',azSun/d2r

  do i=2,NSx-1
     do j=2,NSy-1
        smax = getonehorizon(i,j,azSun)
        !smax = 0.
        Qn(i,j)=flux_wshad(R,sin(betaSun),azSun,surfaceSlope(i,j),azFac(i,j),smax)
     enddo
  enddo

  Tsurf(:,:) = ((1-albedo)*Qn/sigSB)**0.25
  Qrefl=0.; QIR=0.; QIRre=0.

  do n=1,7
     !print *,'Iteration',n

     Qvis(:,:) = Qn + Qrefl
     QIRin(:,:) = QIR + QIRre
     Qshadow1 = 0.; Qshadow2=0.
     do i=2,NSx-1
        do j=2,NSy-1
           QIR(i,j)=0.; Qrefl(i,j)=0.; QIRre(i,j)=0.

           do k=1,cc(i,j)
              iii = ii(i,j,k); jjj = jj(i,j,k)

              Qrefl(i,j) = Qrefl(i,j) + albedo(iii,jjj)*Qvis(iii,jjj)*VF(i,j,k)
              QIR(i,j) = QIR(i,j) + emiss*sigSB*Tsurf(iii,jjj)**4*VF(i,j,k)
              QIRre(i,j) = QIRre(i,j) + (1-emiss)*QIRin(iii,jjj)*VF(i,j,k)
           enddo
           if (Qn(i,j)==0.) then
              Qshadow1 = Qshadow1 + Qrefl(i,j)
              Qshadow2 = Qshadow2 + QIR(i,j)
           endif
        enddo
     enddo
     Qabs(:,:)=(1.-albedo(:,:))*(Qn(:,:)+Qrefl(:,:))+emiss*(QIR+QIRre)  ! Q absorbed
     
     Tsurf = (Qabs/sigSB/emiss)**0.25

     print *,'Iteration',n,Qshadow1,Qshadow2
  enddo

  deallocate(ii, jj, VF)

  open(unit=21,file='qinst.dat',status='unknown',action='write')
  do i=2,NSx-1
     do j=2,NSy-1
        write(21,'(2(i4,1x),f9.2,2x,f6.4,5(1x,f6.1),1x,f5.1)') &
             & i,j,h(i,j),surfaceSlope(i,j),Qn(i,j),Qirre(i,j), &
             & Qabs(i,j),Qir(i,j),Qrefl(i,j),Tsurf(i,j)
     enddo
  enddo
  close(21)

end program cratersQ_equilbr
 

