/*
 Metal Simple Triangle
 (c) Uddipan Mukherjee
 */

#import "AAPLRenderer.h"
#import "AAPLViewController.h"
#import "AAPLView.h"
#import "AAPLTransforms.h"
#import "AAPLSharedTypes.h"

using namespace AAPL;
using namespace simd;


@implementation AAPLRenderer
{
    
    // renderer global ivars
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    
    id <MTLBuffer> posBuf1, posBuf2;
}

- (instancetype)init
{
    self = [super init];
    return self;
}

#pragma mark Configure

- (void)configure:(AAPLView *)view
{
    // find a usable Device
    _device = view.device;
    
    // setup view with drawable formats
    view.depthPixelFormat   = MTLPixelFormatDepth32Float;
    view.stencilPixelFormat = MTLPixelFormatInvalid;
    view.sampleCount        = 2;
    
    // create a new command queue
    _commandQueue = [_device newCommandQueue];
    
    _defaultLibrary = [_device newDefaultLibrary];
    if(!_defaultLibrary) {
        NSLog(@">> ERROR: Couldnt create a default shader library");
        // assert here becuase if the shader libary isn't loading, nothing good will happen
        assert(0);
    }
    
    if (![self preparePipelineState:view])
    {
        NSLog(@">> ERROR: Couldnt create a valid pipeline state");
        
        // cannot render anything without a valid compiled pipeline state object.
        assert(0);
    }
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

}

- (BOOL)preparePipelineState:(AAPLView *)view
{
    // get the fragment function from the library
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"solidTriangleFragment_Red"];
    if(!fragmentProgram)
        NSLog(@">> ERROR: Couldn't load fragment function from default library");
    
    // get the vertex function from the library
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"solidTriangleVertex_vFetch"];
    if(!vertexProgram)
        NSLog(@">> ERROR: Couldn't load vertex function from default library");
    
    static const float posData1[] =
    {
        -1.0f,  1.0f, 0.0f, 1.0f,
        1.0f,  1.0f, 0.0f, 1.0f,
        1.0f, -1.0f, 0.0f, 1.0f,
    };
    
    static const float posData2[] =
    {
        -1.0f,  1.0f, 0.0f, 1.0f,
        -1.0f, -1.0f, 0.0f, 1.0f,
        1.0f, -1.0f, 0.0f, 1.0f,
    };
    
    posBuf1 = [_device newBufferWithLength:sizeof(posData1) options:0];
    memcpy([posBuf1 contents], posData1, sizeof(posData1));
    posBuf2 = [_device newBufferWithLength:sizeof(posData2) options:0];
    memcpy([posBuf2 contents], posData2, sizeof(posData2));
    
    // create a pipeline state descriptor which can be used to create a compiled pipeline state object
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    // Now again with a proper vertex buffer.
    MTLVertexDescriptor* vertexDescriptor      = [[MTLVertexDescriptor alloc] init];
    vertexDescriptor.layouts[0].stride         = 4 * sizeof(float);
    vertexDescriptor.attributes[0].format      = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    
    pipelineStateDescriptor.label                           = @"MyPipeline";
    pipelineStateDescriptor.sampleCount                     = view.sampleCount;
    pipelineStateDescriptor.vertexFunction                  = vertexProgram;
    pipelineStateDescriptor.fragmentFunction                = fragmentProgram;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineStateDescriptor.depthAttachmentPixelFormat      = view.depthPixelFormat;
    pipelineStateDescriptor.vertexDescriptor                = vertexDescriptor;
    
    // create a compiled pipeline state object. Shader functions (from the render pipeline descriptor)
    // are compiled when this is created unlessed they are obtained from the device's cache
    NSError *error = nil;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if(!_pipelineState) {
        NSLog(@">> ERROR: Failed Aquiring pipeline state: %@", error);
        return NO;
    }
    
    return YES;
}

#pragma mark Render

- (void)render:(AAPLView *)view
{
    // create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // create a render command encoder so we can render into something
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"Simple"];
        [renderEncoder setDepthStencilState:_depthState];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setVertexBuffer:posBuf2 offset:0 atIndex:0];
        
        // tell the render context we want to draw our primitives
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        
        [renderEncoder endEncoding];
        [renderEncoder popDebugGroup];
        
        // schedule a present once rendering to the framebuffer is complete
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    
    // finalize rendering here. this will push the command buffer to the GPU
    [commandBuffer commit];

}

- (void)reshape:(AAPLView *)view
{

}

// just use this to update app globals
- (void)update:(AAPLViewController *)controller
{
    //_rotation += controller.timeSinceLastDraw * 50.0f;
}

#pragma mark Update


@end
