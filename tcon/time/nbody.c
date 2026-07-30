/* N-body simulation — floating-point heavy, from the Computer Language Benchmarks Game. */
#include <stdio.h>
#include <math.h>
#define NB 5
static double px[NB],py[NB],pz[NB],vx[NB],vy[NB],vz[NB],mass[NB];

static void setup(void) {
    double pi = 3.141592653589793, solar = 4.0*pi*pi, dpy = 365.24;
    px[0]=0;py[0]=0;pz[0]=0;vx[0]=0;vy[0]=0;vz[0]=0;mass[0]=solar;
    px[1]=4.84143144246472090;py[1]=-1.16032004402742839;pz[1]=-0.103622044471123109;
    vx[1]=0.00166007664274403694*dpy;vy[1]=0.00769901118419740425*dpy;vz[1]=-0.0000690460016972063023*dpy;
    mass[1]=0.000954791938424326609*solar;
    px[2]=8.34336671824457987;py[2]=4.12479856412430479;pz[2]=-0.403523417114321381;
    vx[2]=-0.00276742510726862411*dpy;vy[2]=0.00499852801234917238*dpy;vz[2]=0.0000230417297573763929*dpy;
    mass[2]=0.000285885980666130812*solar;
    px[3]=12.8943695621391310;py[3]=-15.1111514016986312;pz[3]=-0.223307578892655734;
    vx[3]=0.00296460137564761618*dpy;vy[3]=0.00237847173959480950*dpy;vz[3]=-0.0000296589568540237556*dpy;
    mass[3]=0.0000436624404335156298*solar;
    px[4]=15.3796971148509165;py[4]=-25.9193146099879641;pz[4]=0.179258772950371181;
    vx[4]=0.00268067772490389322*dpy;vy[4]=0.00162824170038242295*dpy;vz[4]=-0.0000951592254519715870*dpy;
    mass[4]=0.0000515138902046611451*solar;
    double sx=0,sy=0,sz=0;
    for (int i=0;i<NB;i++){sx+=vx[i]*mass[i];sy+=vy[i]*mass[i];sz+=vz[i]*mass[i];}
    vx[0]=-sx/solar; vy[0]=-sy/solar; vz[0]=-sz/solar;
}

static void advance(double dt) {
    for (int i=0;i<NB;i++) {
        for (int j=i+1;j<NB;j++) {
            double dx=px[i]-px[j], dy=py[i]-py[j], dz=pz[i]-pz[j];
            double d2=dx*dx+dy*dy+dz*dz, dist=sqrt(d2), mag=dt/(d2*dist);
            vx[i]-=dx*mass[j]*mag; vy[i]-=dy*mass[j]*mag; vz[i]-=dz*mass[j]*mag;
            vx[j]+=dx*mass[i]*mag; vy[j]+=dy*mass[i]*mag; vz[j]+=dz*mass[i]*mag;
        }
    }
    for (int i=0;i<NB;i++){px[i]+=dt*vx[i];py[i]+=dt*vy[i];pz[i]+=dt*vz[i];}
}

static double energy(void) {
    double e=0;
    for (int i=0;i<NB;i++) {
        e += 0.5*mass[i]*(vx[i]*vx[i]+vy[i]*vy[i]+vz[i]*vz[i]);
        for (int j=i+1;j<NB;j++) {
            double dx=px[i]-px[j], dy=py[i]-py[j], dz=pz[i]-pz[j];
            e -= (mass[i]*mass[j])/sqrt(dx*dx+dy*dy+dz*dz);
        }
    }
    return e;
}

int main(void) {
    setup();
    for (int i=0;i<20000000;i++) advance(0.01);
    printf("%f\n", energy());
    return 0;
}
