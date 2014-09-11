---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE ViewPatterns #-}

module Main where

import Flowbox.Prelude as P hiding (zoom, constant)

import Flowbox.Graphics.Composition.Generators.Filter
import Flowbox.Graphics.Composition.Generators.Filter as Conv
import Flowbox.Graphics.Composition.Generators.Gradient
import Flowbox.Graphics.Composition.Generators.Keyer
import Flowbox.Graphics.Composition.Generators.Matrix
import Flowbox.Graphics.Composition.Generators.Pipe
import Flowbox.Graphics.Composition.Generators.Rasterizer
import Flowbox.Graphics.Composition.Generators.Sampler
import Flowbox.Graphics.Composition.Generators.Shape
import Flowbox.Graphics.Composition.Generators.Stencil as Stencil
import Flowbox.Graphics.Composition.Generators.Structures as S
import Flowbox.Graphics.Composition.Generators.Transform

import Flowbox.Graphics.Composition.Dither

import Flowbox.Math.Matrix as M
import Flowbox.Graphics.Utils

import qualified Data.Array.Accelerate              as A
import qualified Data.Array.Accelerate.Data.Complex as A

import Linear.V2
import Math.Coordinate.Cartesian as Cartesian
import Math.Metric
import Math.Space.Space

import Utils

import Data.Foldable

-- Test helpers
forAllChannels :: String -> (Matrix2 Float -> Matrix2 Float) -> IO ()
forAllChannels image process = do
    (r, g, b, a) <- testLoadRGBA' $ "samples/" P.++ image
    testSaveRGBA' "out.png" (process r) (process g) (process b) (process a)

--
-- Draws all the existing types of gradients using ContactSheet.
-- (General geometry test)

gradientsTest :: IO ()
gradientsTest = do
    let reds   = [Tick 0.0 1.0 1.0, Tick 0.25 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]
    let greens = [Tick 0.0 1.0 1.0, Tick 0.50 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]
    let blues  = [Tick 0.0 1.0 1.0, Tick 0.75 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]

    let alphas = [Tick 0.0 1.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]
    let gray   = [Tick 0.0 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]

    let weightFun tickPos val1 weight1 val2 weight2 = mix tickPos val1 val2
    let mapper = flip colorMapper weightFun
    let center = translate (V2 (0.5) (0.5)) .zoom (V2 0.5 0.5)
    let grad1 t = center $ mapper t circularShape
    let grad2 t = center $ mapper t diamondShape
    let grad3 t = center $ mapper t squareShape
    let grad4 t = center $ mapper t conicalShape
    let grad5 t = center $ mapper t $ radialShape (Minkowski 0.6)
    let grad6 t = center $ mapper t $ radialShape (Minkowski 3)
    let grad7 t = mapper t $ linearShape
    let grad8   = center . turn (45 * pi / 180) $ mapper gray conicalShape
    
    let raster t = gridRasterizer (Grid 720 480) (Grid 4 2) monosampler [grad1 t, grad2 t, grad3 t, grad4 t, grad5 t, grad6 t, grad7 t, grad8]
    --let raster t = rasterizer $ monosampler $ scaleTo (Grid 720 480) $ grad4 t
    testSaveRGBA' "out.png" (raster reds) (raster greens) (raster blues) (raster alphas)

--
-- Draws single conical gradient rotated 84deg
-- (Multisampling test)
--
multisamplerTest :: IO ()
multisamplerTest = do
    let gray   = [Tick 0.0 0.0 1.0, Tick 1.0 1.0 1.0] :: [Tick Float Float Float]
    let mysampler = multisampler (normalize $ toMatrix 10 box)
    let weightFun tickPos val1 weight1 val2 weight2 = mix tickPos val1 val2
    let mapper = flip colorMapper weightFun
    let shape = scaleTo (Grid 720 480) conicalShape
    let grad      = rasterizer $ mysampler $ translate (V2 (720/2) (480/2)) $ turn (84 * pi / 180) $ mapper gray shape
    testSaveChan' "out.png" grad

--
-- Upcales lena 64x64 image into 720x480 one
-- (Filtering test)
--
scalingTest :: Filter Float -> IO ()
scalingTest flt = do
    let process x = rasterizer $ monosampler 
                               $ scale (V2 (720 / 64) (480 / 64))
                               $ interpolator flt 
                               $ fromMatrix A.Clamp x
    forAllChannels "lena_small.bmp" process

--
-- Applies 2 pass gaussian blur onto the 4k image
-- (Convolution regression test)
--
gaussianTest :: Exp Int -> IO ()
gaussianTest kernSize = do
    let hmat = id M.>-> normalize $ toMatrix (Grid 1 (variable kernSize)) $ gauss 1.0
    let vmat = id M.>-> normalize $ toMatrix (Grid (variable kernSize) 1) $ gauss 1.0
    let p = pipe A.Clamp
    let process x = rasterizer $ id `p` Conv.filter 1 vmat `p` Conv.filter 1 hmat `p` id $ fromMatrix A.Clamp x
    forAllChannels "moonbow.bmp" process

--
-- Applies laplacian edge detector to Lena image
-- (Edge detection test)
--
laplacianTest :: Exp Int -> Exp Float -> Exp Float -> IO ()
laplacianTest kernSize crossVal sideVal = do
    let flt = laplacian (variable crossVal) (variable sideVal) (pure $ variable kernSize)
    let p = pipe A.Clamp
    let process x = rasterizer $ id `p` Conv.filter 1 flt `p` id $ fromMatrix A.Clamp x
    forAllChannels "lena.bmp" process

--
-- Applies morphological operators to Lena image
-- (Morphology test)
--
morphologyTest :: Exp Int -> IO ()
morphologyTest size = do
    let l c = fromMatrix A.Clamp c
    let v = pure $ variable size
    let morph1 c = nearest $ closing v $ l c -- Bottom left
    let morph2 c = nearest $ opening v $ l c -- Bottom right
    let morph3 c = nearest $ dilate  v $ l c -- Top left
    let morph4 c = nearest $ erode   v $ l c -- Top right

    let process chan = gridRasterizer 512 (Grid 2 2) monosampler [morph1 chan, morph2 chan, morph3 chan, morph4 chan]
    forAllChannels "lena.bmp" process

--
-- Applies directional motion blur to Lena image
-- (Simple rotational convolution)
--
motionBlur :: Exp Int -> Exp Float -> IO ()
motionBlur size angle = do
    let kern = monosampler
             $ rotateCenter (variable angle)
             $ nearest
             $ rectangle (Grid (variable size) 1) 1 0
    let process x = rasterizer $ normStencil (+) kern (+) 0 $ fromMatrix A.Clamp x
    forAllChannels "lena.bmp" process

--
-- Radial blur test
-- (Simple rotational convolution)
--
fromPolarMapping :: (Elt a, IsFloating a, Elt e) => CartesianGenerator (Exp a) (Exp e) -> CartesianGenerator (Exp a) (Exp e)
fromPolarMapping (Generator cnv gen) = Generator cnv $ \(Point2 x y) -> 
    let Grid cw ch = fmap A.fromIntegral cnv
        radius = (sqrt $ x * x + y * y) / (sqrt $ cw * cw + ch * ch)
        angle  = atan2 y x / (2 * pi)
    in gen (Point2 (angle * cw) (radius * ch))

toPolarMapping :: (Elt a, IsFloating a, Elt e) => CartesianGenerator (Exp a) (Exp e) -> CartesianGenerator (Exp a) (Exp e)
toPolarMapping (Generator cnv gen) = Generator cnv $ \(Point2 angle' radius') -> 
    let Grid cw ch = fmap A.fromIntegral cnv
        angle = (angle' / cw) * 2 * pi
        radius = (radius' / ch) * (sqrt $ cw * cw + ch * ch)
    in gen (Point2 (radius * cos angle) (radius * sin angle))

radialBlur :: Exp Int -> Exp Float -> IO ()
radialBlur size angle = do
    let kern = monosampler
             $ rotateCenter (variable angle)
             $ nearest
             $ rectangle (Grid (variable size) 1) 1 0
    let process x = rasterizer 
                  $ monosampler 
                  $ translate (V2 (256) (256))
                  $ fromPolarMapping
                  $ nearest
                  $ normStencil (+) kern (+) 0 
                  $ monosampler
                  $ toPolarMapping 
                  $ translate (V2 (-256) (-256))
                  $ nearest 
                  $ fromMatrix A.Clamp x
    forAllChannels "lena.bmp" process

--
-- Defocus test
--
defocusBlur :: Exp Int -> IO ()
defocusBlur size = do
   let kern = ellipse (pure $ variable size) 1 (0 :: Exp Float)
   let process x = rasterizer $ normStencil (+) kern (+) 0 $ fromMatrix A.Clamp x
   forAllChannels "lena.bmp" process

--
-- Bounduary test
--
boundTest :: IO ()
boundTest = do
   let mysampler = multisampler (normalize $ toMatrix 10 box)
   let mask = mysampler $ scale 0.25 $ nearest $ bound A.Mirror $ ellipse 200 1 (0 :: Exp Float)
   testSaveChan' "out.png" (rasterizer mask)

--
-- Applies Kirsch Operator to red channel of Lena image. Available operators: prewitt, sobel, sharr
-- (Advanced rotational convolution, Edge detection test)
--
--rotational :: Exp Float -> Matrix2 Float -> Matrix2 Float -> DiscreteGenerator (Exp Float)
--rotational phi mat chan = id `p` Conv.filter 1 edgeKern `p` id $ fromMatrix A.Clamp chan
--    where edgeKern = rotateMat (phi * pi / 180) (Constant 0) mat
--          p = pipe 512 A.Clamp

--kirschTest :: Matrix2 Float -> IO ()
--kirschTest edgeOp = do
--    (r :: Matrix2 Float, g, b, a) <- testLoadRGBA' "samples/lena.bmp"  
--    let k alpha = rotational alpha edgeOp r
--    let max8 a b c d e f g h = a `min` b `min` c `min` d `min` e `min` f `min` g `min` h
--    let res = rasterizer 512 $ max8 <$> (k 0) <*> (k 45) <*> (k 90) <*> (k 135) <*> (k 180) <*> (k 225) <*> (k 270) <*> (k 315)
--    testSaveChan' "out.png" res


--
-- Unsharp mask - FIXME [kl]
-- (Sharpening test)
--
unsharpMaskTest :: Exp Float -> Exp Int -> IO ()
unsharpMaskTest sigma kernSize = do
    let flt = normalize $ toMatrix (Grid (variable kernSize) (variable kernSize)) $ dirac (variable sigma) - gauss 1.0
    let p = pipe A.Clamp
    let process x = rasterizer $ id `p` Conv.filter 1 flt `p` id $ fromMatrix A.Clamp x
    forAllChannels "lena.bmp" process

keyerTest :: Exp Float -> Exp Float -> Exp Float -> Exp Float -> IO ()
keyerTest w x y z = do
    (r :: Matrix2 Float, g, b, a) <- testLoadRGBA' "samples/keying/greenscreen.jpg"
    let process c = rasterizer $ keyer (A.lift (w, x, y, z)) $ fromMatrix A.Clamp c
    testSaveRGBA' "out.png" r g b (process g)

--
-- FFT test
--
fftTest :: (Exp Float -> Exp Float) -> IO ()
fftTest response = do
    -- Test with response = \x -> abs $ 50 * (x - 0.012)
    let process = fftFilter run $ \freq ampl -> ampl * clamp' 0 2 (response $ freq / 150)
    forAllChannels "edge/mountain.png" process

--
-- Dither test
--

ditherTest :: IO ()
ditherTest = do
    (r :: Matrix2 Float, g, b, a) <- testLoadRGBA' "samples/edge/mountain.png"
    let mydither = dither floydSteinberg 2
    r' <- mutableProcess run mydither r
    g' <- mutableProcess run mydither g
    b' <- mutableProcess run mydither b
    a' <- mutableProcess run mydither a
    testSaveRGBA' "out.png" r' g' b' a'
    --putStrLn "Szatan"

main :: IO ()
main = do
    ditherTest
    --putStrLn "Running gauss 50x50..."
    --gaussianTest (50 :: Exp Int)
