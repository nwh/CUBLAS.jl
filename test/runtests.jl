import Base.dot
import Base.LinAlg.BLAS
using CUBLAS
using CUDArt
using Base.Test

m = 20
n = 35
k = 13

function blasabs(A)
    return abs(real(A)) + abs(imag(A))
end

#################
# level 1 tests #
#################

# test blascopy!
function test_blascopy!{T}(A::Array{T})
    @test ndims(A) == 1
    n1 = length(A)
    d_A = CudaArray(A)
    d_B = CudaArray(T,n1)
    CUBLAS.blascopy!(n,d_A,1,d_B,1)
    B = to_host(d_B)
    @test A == B
end
test_blascopy!(Float32[1:m])
test_blascopy!(Float64[1:m])
test_blascopy!(Float32[1:m]+im*Float32[1:m])
test_blascopy!(Float64[1:m]+im*Float64[1:m])

# test scal!
function test_scal!{T}(alpha,A::Array{T})
    @test ndims(A) == 1
    n1 = length(A)
    d_A = CudaArray(A)
    CUBLAS.scal!(n1,alpha,d_A,1)
    A1 = to_host(d_A)
    @test_approx_eq(alpha*A,A1)
end
test_scal!(2.0f0,Float32[1:m])
test_scal!(2.0,Float64[1:m])
test_scal!(1.0f0+im*1.0f0,Float32[1:m]+im*Float32[1:m])
test_scal!(1.0+im*1.0,Float64[1:m]+im*Float64[1:m])
test_scal!(2.0f0,Float32[1:m]+im*Float32[1:m])
test_scal!(2.0,Float64[1:m]+im*Float64[1:m])

# test dot
function test_dot(A,B)
    @test ndims(A) == 1
    @test ndims(B) == 1
    @test length(A) == length(B)
    n1 = length(A)
    d_A = CudaArray(A)
    d_B = CudaArray(B)
    cuda_dot1 = CUBLAS.dot(n1,d_A,1,d_B,1)
    cuda_dot2 = CUBLAS.dot(d_A,d_B)
    host_dot = dot(A,B)
    @test_approx_eq(cuda_dot1,host_dot)
    @test_approx_eq(cuda_dot2,host_dot)
end
test_dot(Float32[1:m],Float32[1:m])
test_dot(Float64[1:m],Float64[1:m])

# test dotu
function test_dotu(A,B)
    @test ndims(A) == 1
    @test ndims(B) == 1
    @test length(A) == length(B)
    n1 = length(A)
    d_A = CudaArray(A)
    d_B = CudaArray(B)
    cuda_dot1 = CUBLAS.dotu(n1,d_A,1,d_B,1)
    cuda_dot2 = CUBLAS.dotu(d_A,d_B)
    host_dot = A.'*B
    @test_approx_eq(cuda_dot1,host_dot)
    @test_approx_eq(cuda_dot2,host_dot)
end
test_dotu(rand(Complex64,m),rand(Complex64,m))
test_dotu(rand(Complex128,m),rand(Complex128,m))

# test dotc
function test_dotc(A,B)
    @test ndims(A) == 1
    @test ndims(B) == 1
    @test length(A) == length(B)
    n1 = length(A)
    d_A = CudaArray(A)
    d_B = CudaArray(B)
    cuda_dot1 = CUBLAS.dotc(n1,d_A,1,d_B,1)
    cuda_dot2 = CUBLAS.dotc(d_A,d_B)
    host_dot = A'*B
    @test_approx_eq(cuda_dot1,host_dot)
    @test_approx_eq(cuda_dot2,host_dot)
end
test_dotc(rand(Complex64,m),rand(Complex64,m))
test_dotc(rand(Complex128,m),rand(Complex128,m))

# test nrm2
function test_nrm2(A)
    @test ndims(A) == 1
    n1 = length(A)
    d_A = CudaArray(A)
    cuda_nrm2_1 = CUBLAS.nrm2(n1,d_A,1)
    cuda_nrm2_2 = CUBLAS.nrm2(d_A)
    host_nrm2 = norm(A)
    @test_approx_eq(cuda_nrm2_1,host_nrm2)
    @test_approx_eq(cuda_nrm2_2,host_nrm2)
end
test_nrm2(rand(Float32,m))
test_nrm2(rand(Float64,m))
test_nrm2(rand(Complex64,m))
test_nrm2(rand(Complex128,m))

# test asum
function test_asum(A)
    @test ndims(A) == 1
    n1 = length(A)
    d_A = CudaArray(A)
    cuda_asum1 = CUBLAS.asum(n1,d_A,1)
    cuda_asum2 = CUBLAS.asum(d_A)
    host_asum = sum(abs(real(A)) + abs(imag(A)))
    @test_approx_eq(cuda_asum1,host_asum)
    @test_approx_eq(cuda_asum2,host_asum)
end
test_asum(Float32[1:m])
test_asum(Float64[1:m])
test_asum(rand(Complex64,m))
test_asum(rand(Complex128,m))

# test axpy!
function test_axpy!_1(alpha,A,B)
    @test length(A) == length(B)
    n1 = length(A)
    d_A = CudaArray(A)
    d_B1 = CudaArray(B)
    CUBLAS.axpy!(n1,alpha,d_A,1,d_B1,1)
    B1 = to_host(d_B1)
    host_axpy = alpha*A + B
    @test_approx_eq(host_axpy,B1)
end
test_axpy!_1(2.0f0,rand(Float32,m),rand(Float32,m))
test_axpy!_1(2.0,rand(Float64,m),rand(Float64,m))
test_axpy!_1(2.0f0+im*2.0f0,rand(Complex64,m),rand(Complex64,m))
test_axpy!_1(2.0+im*2.0,rand(Complex128,m),rand(Complex128,m))

function test_axpy!_2(alpha,A,B)
    @test length(A) == length(B)
    n1 = length(A)
    d_A = CudaArray(A)
    d_B1 = CudaArray(B)
    CUBLAS.axpy!(alpha,d_A,d_B1)
    B1 = to_host(d_B1)
    host_axpy = alpha*A + B
    @test_approx_eq(host_axpy,B1)
end
test_axpy!_2(2.0f0,rand(Float32,m),rand(Float32,m))
test_axpy!_2(2.0,rand(Float64,m),rand(Float64,m))
test_axpy!_2(2.0f0+im*2.0f0,rand(Complex64,m),rand(Complex64,m))
test_axpy!_2(2.0+im*2.0,rand(Complex128,m),rand(Complex128,m))

function test_axpy!_3(alpha,A,B)
    @test length(A) == length(B)
    n1 = length(A)
    d_A = CudaArray(A)
    d_B1 = CudaArray(B)
    CUBLAS.axpy!(alpha,d_A,1:2:n1,d_B1,1:2:n1)
    B1 = to_host(d_B1)
    host_axpy = B
    host_axpy[1:2:n1] = alpha*A[1:2:n1] + B[1:2:n1]
    @test_approx_eq(host_axpy,B1)
end
test_axpy!_3(2.0f0,rand(Float32,m),rand(Float32,m))
test_axpy!_3(2.0,rand(Float64,m),rand(Float64,m))
test_axpy!_3(2.0f0+im*2.0f0,rand(Complex64,m),rand(Complex64,m))
test_axpy!_3(2.0+im*2.0,rand(Complex128,m),rand(Complex128,m))

function test_axpy!_4(alpha,A,B)
    @test length(A) == length(B)
    n1 = length(A)
    d_A = CudaArray(A)
    d_B1 = CudaArray(B)
    r = 1:div(n1,2)
    CUBLAS.axpy!(alpha,d_A,r,d_B1,r)
    B1 = to_host(d_B1)
    host_axpy = B
    host_axpy[r] = alpha*A[r] + B[r]
    @test_approx_eq(host_axpy,B1)
end
test_axpy!_4(2.0f0,rand(Float32,m),rand(Float32,m))
test_axpy!_4(2.0,rand(Float64,m),rand(Float64,m))
test_axpy!_4(2.0f0+im*2.0f0,rand(Complex64,m),rand(Complex64,m))
test_axpy!_4(2.0+im*2.0,rand(Complex128,m),rand(Complex128,m))

# test iamax & iamin
function test_iamaxmin(A)
    n1 = length(A)
    d_A = CudaArray(A)
    Aabs = blasabs(A)
    imin1 = CUBLAS.iamin(n1,d_A,1)
    imax1 = CUBLAS.iamax(n1,d_A,1)
    imin2 = CUBLAS.iamin(d_A)
    imax2 = CUBLAS.iamax(d_A)
    host_imin = indmin(Aabs)
    host_imax = indmax(Aabs)
    @test imin1 == imin2 == host_imin
    @test imin1 == imin2 == host_imin
end
test_iamaxmin(rand(Float32,m))
test_iamaxmin(rand(Float64,m))
test_iamaxmin(rand(Complex64,m))
test_iamaxmin(rand(Complex128,m))

#################
# level 2 tests #
#################

# test gemv!
function test_gemv!(elty)
    alpha = convert(elty,1)
    beta = convert(elty,1)
    A = rand(elty,m,n)
    d_A = CudaArray(A)
    # test y = A*x + y
    x = rand(elty,n)
    d_x = CudaArray(x)
    y = rand(elty,m)
    d_y = CudaArray(y)
    y = A*x + y
    CUBLAS.gemv!('N',alpha,d_A,d_x,beta,d_y)
    h_y = to_host(d_y)
    @test_approx_eq(y,h_y)
    # test x = A.'*y + x
    x = rand(elty,n)
    d_x = CudaArray(x)
    y = rand(elty,m)
    d_y = CudaArray(y)
    x = A.'*y + x
    CUBLAS.gemv!('T',alpha,d_A,d_y,beta,d_x)
    h_x = to_host(d_x)
    @test_approx_eq(x,h_x)
    # test x = A'*y + x
    x = rand(elty,n)
    d_x = CudaArray(x)
    y = rand(elty,m)
    d_y = CudaArray(y)
    x = A'*y + x
    CUBLAS.gemv!('C',alpha,d_A,d_y,beta,d_x)
    h_x = to_host(d_x)
    @test_approx_eq(x,h_x)
end
test_gemv!(Float32)
test_gemv!(Float64)
test_gemv!(Complex64)
test_gemv!(Complex128)

# test gemv
function test_gemv(elty)
    alpha = convert(elty,2)
    A = rand(elty,m,n)
    d_A = CudaArray(A)
    # test y = alpha*(A*x)
    x = rand(elty,n)
    d_x = CudaArray(x)
    y1 = alpha*(A*x)
    y2 = A*x
    d_y1 = CUBLAS.gemv('N',alpha,d_A,d_x)
    d_y2 = CUBLAS.gemv('N',d_A,d_x)
    h_y1 = to_host(d_y1)
    h_y2 = to_host(d_y2)
    @test_approx_eq(y1,h_y1)
    @test_approx_eq(y2,h_y2)
    # test x = alpha*(A.'*y)
    y = rand(elty,m)
    d_y = CudaArray(y)
    x1 = alpha*(A.'*y)
    x2 = A.'*y
    d_x1 = CUBLAS.gemv('T',alpha,d_A,d_y)
    d_x2 = CUBLAS.gemv('T',d_A,d_y)
    h_x1 = to_host(d_x1)
    h_x2 = to_host(d_x2)
    @test_approx_eq(x1,h_x1)
    @test_approx_eq(x2,h_x2)
    # test x = alpha*(A'*y)
    y = rand(elty,m)
    d_y = CudaArray(y)
    x1 = alpha*(A'*y)
    x2 = A'*y
    d_x1 = CUBLAS.gemv('C',alpha,d_A,d_y)
    d_x2 = CUBLAS.gemv('C',d_A,d_y)
    h_x1 = to_host(d_x1)
    h_x2 = to_host(d_x2)
    @test_approx_eq(x1,h_x1)
    @test_approx_eq(x2,h_x2)
end
test_gemv(Float32)
test_gemv(Float64)
test_gemv(Complex64)
test_gemv(Complex128)

##############
# test gbmv! #
##############

function test_gbmv!(elty)
    # parameters
    alpha = convert(elty,2)
    beta = convert(elty,3)
    # bands
    ku = 2
    kl = 3
    # generate banded matrix
    A = rand(elty,m,n)
    A = bandex(A,kl,ku)
    # get packed format
    Ab = band(A,kl,ku)
    d_Ab = CudaArray(Ab)
    # test y = alpha*A*x + beta*y
    x = rand(elty,n)
    d_x = CudaArray(x)
    y = rand(elty,m)
    d_y = CudaArray(y)
    CUBLAS.gbmv!('N',m,kl,ku,alpha,d_Ab,d_x,beta,d_y)
    BLAS.gbmv!('N',m,kl,ku,alpha,Ab,x,beta,y)
    h_y = to_host(d_y)
    @test_approx_eq(y,h_y)
    # test y = alpha*A.'*x + beta*y
    x = rand(elty,n)
    d_x = CudaArray(x)
    y = rand(elty,m)
    d_y = CudaArray(y)
    CUBLAS.gbmv!('T',m,kl,ku,alpha,d_Ab,d_y,beta,d_x)
    BLAS.gbmv!('T',m,kl,ku,alpha,Ab,y,beta,x)
    h_x = to_host(d_x)
    @test_approx_eq(x,h_x)
    # test y = alpha*A'*x + beta*y
    x = rand(elty,n)
    d_x = CudaArray(x)
    y = rand(elty,m)
    d_y = CudaArray(y)
    CUBLAS.gbmv!('C',m,kl,ku,alpha,d_Ab,d_y,beta,d_x)
    BLAS.gbmv!('C',m,kl,ku,alpha,Ab,y,beta,x)
    h_x = to_host(d_x)
    @test_approx_eq(x,h_x)
end
test_gbmv!(Float32)
test_gbmv!(Float64)
test_gbmv!(Complex64)
test_gbmv!(Complex128)

# TODO: complete this test when BLAS.gbmv is fixed
function test_gbmv(elty)
    # parameters
    alpha = convert(elty,2)
    # bands
    ku = 2
    kl = 3
    # generate banded matrix
    A = rand(elty,m,n)
    A = bandex(A,kl,ku)
    # get packed format
    Ab = band(A,kl,ku)
    d_Ab = CudaArray(Ab)
    # test y = alpha*A*x
    x = rand(elty,n)
    d_x = CudaArray(x)
    d_y = CUBLAS.gbmv('N',m,kl,ku,alpha,d_Ab,d_x)
    y = zeros(elty,m)
    #y = BLAS.gbmv('N',m,kl,ku,alpha,Ab,x)
    h_y = to_host(d_y)
    #@test_approx_eq(y,h_y)
end
test_gbmv(Float32)
test_gbmv(Float64)
test_gbmv(Complex64)
test_gbmv(Complex128)

#############
# test symv #
#############

function test_symv!(elty)
    # parameters
    alpha = convert(elty,2)
    beta = convert(elty,3)
    # generate symmetric matrix
    A = rand(elty,m,m)
    A = A + A.'
    # generate vectors
    x = rand(elty,m)
    y = rand(elty,m)
    # copy to device
    d_A = CudaArray(A)
    d_x = CudaArray(x)
    d_y = CudaArray(y)
    # execute on host
    BLAS.symv!('U',alpha,A,x,beta,y)
    # execute on device
    CUBLAS.symv!('U',alpha,d_A,d_x,beta,d_y)
    # compare results
    h_y = to_host(d_y)
    @test_approx_eq(y,h_y)
end
test_symv!(Float32)
test_symv!(Float64)
test_symv!(Complex64)
test_symv!(Complex128)

function test_symv(elty)
    # generate symmetric matrix
    A = rand(elty,m,m)
    A = A + A.'
    # generate vectors
    x = rand(elty,m)
    # copy to device
    d_A = CudaArray(A)
    d_x = CudaArray(x)
    # execute on host
    y = BLAS.symv('U',A,x)
    # execute on device
    d_y = CUBLAS.symv('U',d_A,d_x)
    # compare results
    h_y = to_host(d_y)
    @test_approx_eq(y,h_y)
end
test_symv(Float32)
test_symv(Float64)
test_symv(Complex64)
test_symv(Complex128)

##############
# test hemv! #
##############

function test_hemv!(elty)
    # parameters
    alpha = convert(elty,2)
    beta = convert(elty,3)
    # generate hermitian matrix
    A = rand(elty,m,m)
    A = A + A'
    # generate vectors
    x = rand(elty,m)
    y = rand(elty,m)
    # copy to device
    d_A = CudaArray(A)
    d_x = CudaArray(x)
    d_y = CudaArray(y)
    # execute on host
    #BLAS.hemv!('U',alpha,A,x,beta,y)
    # execute on device
    CUBLAS.hemv!('U',alpha,d_A,d_x,beta,d_y)
    # compare results
    h_y = to_host(d_y)
    #@test_approx_eq(y,h_y)
end
# BLAS.hemv! is not in julia v0.3.0
test_hemv!(Complex64)
test_hemv!(Complex128)

function test_hemv(elty)
    # generate hermitian matrix
    A = rand(elty,m,m)
    A = A + A.'
    # generate vectors
    x = rand(elty,m)
    # copy to device
    d_A = CudaArray(A)
    d_x = CudaArray(x)
    # execute on host
    #y = BLAS.hemv('U',A,x)
    # execute on device
    d_y = CUBLAS.hemv('U',d_A,d_x)
    # compare results
    h_y = to_host(d_y)
    #@test_approx_eq(y,h_y)
end
test_hemv(Complex64)
test_hemv(Complex128)

##############
# test sbmv! #
##############

function test_sbmv!(elty)
    # parameters
    alpha = convert(elty,3)
    beta = convert(elty,2.5)
    # generate symmetric matrix
    A = rand(elty,m,m)
    A = A + A'
    # restrict to 3 bands
    nbands = 3
    @test m >= 1+nbands
    A = bandex(A,nbands,nbands)
    # convert to 'upper' banded storage format
    AB = band(A,0,nbands)
    # construct x and y
    x = rand(elty,m)
    y = rand(elty,m)
    # move to host
    d_AB = CudaArray(AB)
    d_x = CudaArray(x)
    d_y = CudaArray(y)
    # sbmv!
    CUBLAS.sbmv!('U',nbands,alpha,d_AB,d_x,beta,d_y)
    y = alpha*(A*x) + beta*y
    # compare
    h_y = to_host(d_y)
    @test_approx_eq(y,h_y)
end
test_sbmv!(Float32)
test_sbmv!(Float64)

function test_sbmv(elty)
    # parameters
    alpha = convert(elty,3)
    beta = convert(elty,2.5)
    # generate symmetric matrix
    A = rand(elty,m,m)
    A = A + A'
    # restrict to 3 bands
    nbands = 3
    @test m >= 1+nbands
    A = bandex(A,nbands,nbands)
    # convert to 'upper' banded storage format
    AB = band(A,0,nbands)
    # construct x and y
    x = rand(elty,m)
    y = rand(elty,m)
    # move to host
    d_AB = CudaArray(AB)
    d_x = CudaArray(x)
    # sbmv!
    d_y = CUBLAS.sbmv('U',nbands,d_AB,d_x)
    y = A*x
    # compare
    h_y = to_host(d_y)
    @test_approx_eq(y,h_y)
end
test_sbmv(Float32)
test_sbmv(Float64)

##############
# test trmv! #
##############

function test_trmv!(elty)
    # generate triangular matrix
    A = rand(elty,m,m)
    A = triu(A)
    # generate vector
    x = rand(elty,m)
    # move to device
    d_A = CudaArray(A)
    d_x = CudaArray(x)
    # execute trmv!
    CUBLAS.trmv!('U','N','N',d_A,d_x)
    x = A*x
    # compare
    h_x = to_host(d_x)
    @test_approx_eq(x,h_x)
end
test_trmv!(Float32)
test_trmv!(Float64)
test_trmv!(Complex64)
test_trmv!(Complex128)

function test_trmv(elty)
    # generate triangular matrix
    A = rand(elty,m,m)
    A = triu(A)
    # generate vector
    x = rand(elty,m)
    # move to device
    d_A = CudaArray(A)
    d_x = CudaArray(x)
    # execute trmv!
    d_y = CUBLAS.trmv('U','N','N',d_A,d_x)
    y = A*x
    # compare
    h_y = to_host(d_y)
    @test_approx_eq(y,h_y)
end
test_trmv(Float32)
test_trmv(Float64)
test_trmv(Complex64)
test_trmv(Complex128)
