/*
 * Copyright (c) 2017 Fabian Jäger <fabianjaeger@gmx.net>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Fabian Jäger nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "FGSegmentedProgressBar.h"
#import "NSColor+FGAdditions.h"

@interface FGSegmentedProgressBar ()
- (void) setDefaults;
@end

@implementation FGSegmentedProgressBar

- (instancetype) initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect])
    {
        [self setDefaults];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        [self setDefaults];
    }
    return self;
}

- (void) setDefaults
{
    self.maxValue = CGFLOAT_MAX;
    self.barHeight = 22.0;
    self.drawLegend = YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    //// draw segmented bar first
    NSRect segmentedBarRect = NSMakeRect(dirtyRect.origin.x, dirtyRect.origin.y+dirtyRect.size.height-self.barHeight, dirtyRect.size.width, self.barHeight);
    
    // set overall clipping of our view
    CGFloat cornerRadius = self.barHeight/4.0;
    NSBezierPath* clippingPath = [NSBezierPath bezierPathWithRoundedRect:segmentedBarRect xRadius:cornerRadius yRadius:cornerRadius];
    [clippingPath addClip];
    
    // fill with white background
    [[NSColor whiteColor] set];
    [clippingPath fill];
    
    CGFloat maxValue = self.maxValue;
    if(maxValue == CGFLOAT_MAX)
    {
        maxValue = 0.0;
        // get max value as sum of all segments
        for(NSDictionary* aSegmentDict in self.segments)
        {
            maxValue += [aSegmentDict[FGSegmentValue] floatValue];
        }
    }
    
    // draw each segment individually
    CGFloat segStartX = dirtyRect.origin.x;
    NSUInteger i = 0;
    for(NSDictionary* aSegmentDict in self.segments)
    {
        if(!aSegmentDict[FGSegmentValue])
            continue;
        if([aSegmentDict[FGSegmentValue] floatValue] == 0.0)
            continue;
        
        NSColor* segmentColor = aSegmentDict[FGSegmentColor]?:[NSColor blackColor];
        
        CGFloat segmentValue = [aSegmentDict[FGSegmentValue] floatValue];
        
        CGFloat width = (segmentValue/maxValue)*dirtyRect.size.width;
        width = MAX(width, 2.0);
        
        NSRect segmentRect = NSMakeRect(segStartX, segmentedBarRect.origin.y, width, segmentedBarRect.size.height);
        
        [segmentColor set];
        NSRectFill(segmentRect);
        
        segStartX += width;
        i++;
    }
    
    // draw bounding line
    clippingPath.lineWidth = 1.0;
    [[NSColor lightGrayColor] set];
    [clippingPath stroke];
    
    CGFloat spacing = 4.0;
    
    //// draw legend next
    [[NSBezierPath bezierPathWithRect:dirtyRect] setClip];
    CGFloat legendRectSize = 10.0;
    
    CGFloat legendItemX = spacing + dirtyRect.origin.x;
    CGFloat legendTopY  = dirtyRect.origin.y+dirtyRect.size.height-self.barHeight-spacing*3.0;
    i = 0;
    for(NSDictionary* aSegmentDict in self.segments)
    {
        if(!aSegmentDict[FGSegmentValue])
            continue;
        if([aSegmentDict[FGSegmentValue] floatValue] == 0.0)
            continue;
        
        NSColor* segmentColor = aSegmentDict[FGSegmentColor]?:[NSColor blackColor];
        
        NSString* segmentLabel = aSegmentDict[FGSegmentLabel];
        NSString* segmentValue = aSegmentDict[FGSegmentValueString];
        
        if( !segmentLabel )
            continue;
        
        if( !segmentValue )
            segmentValue = [NSString stringWithFormat:@"%.2f%%", [aSegmentDict[FGSegmentValue] floatValue]/maxValue*100];
        
        // draw legend color rect
        NSRect legendRect = NSMakeRect(legendItemX, legendTopY-legendRectSize, legendRectSize, legendRectSize);
        NSBezierPath* legendPath = [NSBezierPath bezierPathWithRoundedRect:legendRect xRadius:legendRectSize/4.0 yRadius:legendRectSize/4.0];
        
        [segmentColor set];
        [legendPath fill];
        [[NSColor lightGrayColor] set];
        legendPath.lineWidth = 0.5;
        [legendPath stroke];
        
        // draw label next to rect
        CGFloat legendItemLabelX = legendRect.origin.x + legendRect.size.width + spacing*1.5;
        
        NSFont* labelFont = [NSFont boldSystemFontOfSize:10.0];
        NSDictionary* labelAttributes = @{NSFontAttributeName:labelFont};
        NSRect labelBounds = [segmentLabel boundingRectWithSize:dirtyRect.size options:0 attributes:labelAttributes];
        
        NSRect legendItemLabelRect = NSMakeRect(legendItemLabelX, legendRect.origin.y-2.0, labelBounds.size.width, labelBounds.size.height);
        [segmentLabel drawInRect:legendItemLabelRect withAttributes:labelAttributes];
        
        // draw value of legend item
        NSFont* valueFont = [NSFont systemFontOfSize:10.0];
        NSDictionary* valueAttributes = @{NSFontAttributeName:valueFont};
        
        NSRect valueBounds = [segmentValue boundingRectWithSize:dirtyRect.size options:0 attributes:valueAttributes];
        
        NSRect legendItemValueRect = NSMakeRect(legendItemLabelX, legendItemLabelRect.origin.y-spacing*0.5-valueBounds.size.height, valueBounds.size.width, valueBounds.size.height);
        [segmentValue drawInRect:legendItemValueRect withAttributes:valueAttributes];
        
        // prepare for next item
        legendItemX += legendRect.size.width + spacing + MAX(valueBounds.size.width, labelBounds.size.width) + spacing*4.0;
        i++;
    }
}

@end
