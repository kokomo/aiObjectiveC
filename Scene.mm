//
//  Scene.mm
//  aiObjectiveC
//
//  Created by Jørgen P. Tjernø on 10/29/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Scene.h"

#import "Mesh.h"
#import "Material.h"
#import "Node.h"
#import "Animation.h"

#import "NSString+AI.h"

#include "assimp.h"

#include "aiScene.h"
#include "aiPostProcess.h"

@interface Scene ()

@property (nonatomic, retain) NSArray *meshes;
@property (nonatomic, retain) NSArray *materials;
@property (nonatomic, retain) Node *rootNode;

@end

@implementation Scene

@synthesize meshes;
@synthesize materials;
@synthesize rootNode;
@synthesize animations;

+ (id) sceneFromFile:(NSString *)file
{
    return [[[self alloc] initFromFile:file] autorelease];
}

- (id) initFromFile:(NSString *)file
{
    if (self = [super init])
    {
        NSString *filename = [file lastPathComponent];
        NSString *scenePath = [[NSBundle mainBundle] pathForResource:filename
                                                              ofType:@""
                                                         inDirectory:@"Scenes"];

        const aiScene *scene = aiImportFile([scenePath cStringUsingEncoding:NSUTF8StringEncoding], aiProcessPreset_TargetRealtime_Quality);
        if (!scene)
        {
            NSLog(@"Could not load scene from path: %@", scenePath);
            [self release];
            self = nil;
        }
        else if (![self loadScene:scene])
        {
            NSLog(@"Could not create data structure for scene %@", filename);
            [self release];
            self = nil;
        }

        if (scene)
            aiReleaseImport(scene);
    }
    return self;
}

- (void) dealloc
{
    [self setMeshes:nil];
    [self setMaterials:nil];

    [super dealloc];
}

- (BOOL) loadScene:(const aiScene *)scene
{
    if (!scene)
        return NO;
    
    NSMutableArray* newMaterials = [NSMutableArray arrayWithCapacity:scene->mNumMaterials];
    for (int i = 0; i < scene->mNumMaterials; ++i)
    {
        [newMaterials addObject:[Material materialWithAsset:scene->mMaterials[i]]];
    }

    NSMutableArray* newMeshes = [NSMutableArray arrayWithCapacity:scene->mNumMeshes];
    for (int i = 0; i < scene->mNumMeshes; ++i)
    {
        aiMesh *sceneMesh = scene->mMeshes[i];
        Material *material = [newMaterials objectAtIndex:(sceneMesh->mMaterialIndex)];
        Mesh *mesh = [Mesh meshWithAsset:sceneMesh
                                material:material];
        [newMeshes addObject:mesh];
    }

    [self setMaterials:newMaterials];
    [self setMeshes:newMeshes];

    [self setRootNode:[Node nodeWithNode:scene->mRootNode
                                  meshes:meshes]];

    NSMutableDictionary* newAnimations = [NSMutableDictionary dictionaryWithCapacity:scene->mNumAnimations];
    for (int i = 0; i < scene->mNumAnimations; ++i)
    {
        aiAnimation *animation = scene->mAnimations[i];
        [newAnimations setObject:[Animation animationWithAsset:animation]
                          forKey:[NSString stringWithAIString:&animation->mName]];
    }
    [self setAnimations:newAnimations];

    return YES;
}

- (void) render
{
    [rootNode render];
}

@end
