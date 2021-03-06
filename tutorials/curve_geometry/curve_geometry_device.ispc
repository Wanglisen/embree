// Copyright 2009-2020 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "../common/tutorial/tutorial_device.isph"
#include "../common/tutorial/optics.isph"

/* scene data */
RTCScene  g_scene  = NULL;

#define NUM_VERTICES 9
#define NUM_CURVES 6

#define W 2.0f

uniform float hair_vertices[NUM_VERTICES][4] =
{
  { -1.0f, 0.0f, -   W, 0.2f },

  { +0.0f,-1.0f, +0.0f, 0.2f },
  { +1.0f, 0.0f, +   W, 0.2f },
  { -1.0f, 0.0f, +   W, 0.2f },
  { +0.0f,+1.0f, +0.0f, 0.6f },
  { +1.0f, 0.0f, -   W, 0.2f },
  { -1.0f, 0.0f, -   W, 0.2f },

  { +0.0f,-1.0f, +0.0f, 0.2f },
  { +1.0f, 0.0f, +   W, 0.2f },
};

uniform float hair_normals[NUM_VERTICES][4] =
{
  { -1.0f,  0.0f, 0.0f, 0.0f },

  {  0.0f, +1.0f, 0.0f, 0.0f },
  { +1.0f,  0.0f, 0.0f, 0.0f },
  {  0.0f, -1.0f, 0.0f, 0.0f },
  { -1.0f,  0.0f, 0.0f, 0.0f },
  {  0.0f, +1.0f, 0.0f, 0.0f },
  { +1.0f,  0.0f, 0.0f, 0.0f },

  {  0.0f, -1.0f, 0.0f, 0.0f },
  { -1.0f,  0.0f, 0.0f, 0.0f },
};

uniform float hair_vertex_colors[NUM_VERTICES][4] =
{
  {  1.0f,  1.0f,  0.0f, 0.0f },

  {  1.0f,  0.0f,  0.0f, 0.0f },
  {  1.0f,  1.0f,  0.0f, 0.0f },
  {  0.0f,  0.0f,  1.0f, 0.0f },
  {  1.0f,  1.0f,  1.0f, 0.0f },
  {  1.0f,  0.0f,  0.0f, 0.0f },
  {  1.0f,  1.0f,  0.0f, 0.0f },

  {  1.0f,  0.0f,  0.0f, 0.0f },
  {  1.0f,  1.0f,  0.0f, 0.0f },
};

uniform unsigned int hair_indices[NUM_CURVES] = {
  0, 1, 2, 3, 4, 5
};

uniform unsigned int hair_indices_linear[NUM_CURVES] = {
  1, 2, 3, 4, 5, 6
};

uniform int8 hair_flags_linear[NUM_CURVES] = {
  0x3, 0x3, 0x3, 0x3, 0x3, 0x3
};

/* add hair geometry */
uniform unsigned int addCurve (RTCScene scene, uniform RTCGeometryType gtype, const uniform Vec4f& pos)
{
  RTCGeometry geom = rtcNewGeometry (g_device, gtype);
  rtcSetGeometryVertexAttributeCount(geom,1);

  if (gtype == RTC_GEOMETRY_TYPE_FLAT_LINEAR_CURVE || gtype == RTC_GEOMETRY_TYPE_ROUND_LINEAR_CURVE)
    rtcSetSharedGeometryBuffer(geom,RTC_BUFFER_TYPE_INDEX, 0, RTC_FORMAT_UINT,   hair_indices_linear,0, sizeof(uniform unsigned int), NUM_CURVES);
  else
    rtcSetSharedGeometryBuffer(geom,RTC_BUFFER_TYPE_INDEX, 0, RTC_FORMAT_UINT,   hair_indices,       0, sizeof(uniform unsigned int), NUM_CURVES);
      
  uniform Vec4f* uniform verts = (uniform Vec4f* uniform)rtcSetNewGeometryBuffer(geom, RTC_BUFFER_TYPE_VERTEX, 0, RTC_FORMAT_FLOAT4, sizeof(uniform Vec4f), NUM_VERTICES);
  for (uniform int i = 0; i < NUM_VERTICES; i++) {
    verts[i] = pos + make_Vec4f(hair_vertices[i][0],hair_vertices[i][1], hair_vertices[i][2], hair_vertices[i][3]);
  }
  if (gtype == RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_BEZIER_CURVE ||
      gtype == RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_BSPLINE_CURVE ||
      gtype == RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_CATMULL_ROM_CURVE) {
    rtcSetSharedGeometryBuffer(geom, RTC_BUFFER_TYPE_NORMAL, 0, RTC_FORMAT_FLOAT3, hair_normals, 0, sizeof(uniform Vec3fa), NUM_VERTICES);
  }
  
  if (gtype == RTC_GEOMETRY_TYPE_ROUND_LINEAR_CURVE) {
    rtcSetSharedGeometryBuffer(geom, RTC_BUFFER_TYPE_FLAGS, 0, RTC_FORMAT_UCHAR, hair_flags_linear, 0, sizeof(uniform int8), NUM_CURVES);
  }

  rtcSetSharedGeometryBuffer(geom,RTC_BUFFER_TYPE_VERTEX_ATTRIBUTE, 0, RTC_FORMAT_FLOAT3, hair_vertex_colors, 0, sizeof(uniform Vec3fa),       NUM_VERTICES);
  rtcCommitGeometry(geom);
  uniform unsigned int geomID = rtcAttachGeometry(scene,geom);
  rtcReleaseGeometry(geom);
  return geomID;
}

/* adds a ground plane to the scene */
uniform unsigned int addGroundPlane (RTCScene scene_i)
{
  /* create a triangulated plane with 2 triangles and 4 vertices */
  RTCGeometry geom = rtcNewGeometry (g_device, RTC_GEOMETRY_TYPE_TRIANGLE);

  /* set vertices */
  uniform Vertex* uniform vertices = (uniform Vertex* uniform) rtcSetNewGeometryBuffer(geom, RTC_BUFFER_TYPE_VERTEX, 0, RTC_FORMAT_FLOAT3, sizeof(uniform Vertex), 4);
  vertices[0].x = -15; vertices[0].y = -2; vertices[0].z = -15;
  vertices[1].x = -15; vertices[1].y = -2; vertices[1].z = +15;
  vertices[2].x = +15; vertices[2].y = -2; vertices[2].z = -15;
  vertices[3].x = +15; vertices[3].y = -2; vertices[3].z = +15;

  /* set triangles */
  uniform Triangle* uniform triangles = (uniform Triangle* uniform) rtcSetNewGeometryBuffer(geom, RTC_BUFFER_TYPE_INDEX, 0, RTC_FORMAT_UINT3, sizeof(uniform Triangle), 2);
  triangles[0].v0 = 0; triangles[0].v1 = 1; triangles[0].v2 = 2;
  triangles[1].v0 = 1; triangles[1].v1 = 3; triangles[1].v2 = 2;

  rtcCommitGeometry(geom);
  uniform unsigned int geomID = rtcAttachGeometry(scene_i,geom);
  rtcReleaseGeometry(geom);
  return geomID;
}

/* called by the C++ code for initialization */
export void device_init (uniform int8* uniform cfg)
{
  /* create scene */
  g_scene = rtcNewScene(g_device);

  /* add ground plane */
  addGroundPlane(g_scene);

  /* add curves */
  addCurve(g_scene, RTC_GEOMETRY_TYPE_ROUND_LINEAR_CURVE, make_Vec4f(-4.5f, 0.0f, 3.f, 0.0f));
  addCurve(g_scene, RTC_GEOMETRY_TYPE_FLAT_BSPLINE_CURVE, make_Vec4f(-1.5f, 0.0f, 3.f, 0.0f));
  addCurve(g_scene, RTC_GEOMETRY_TYPE_ROUND_BSPLINE_CURVE, make_Vec4f(1.5f, 0.0f, 3.f, 0.0f));
  addCurve(g_scene, RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_BSPLINE_CURVE, make_Vec4f(+4.5f, 0.0f, 3.f, 0.0f));

  addCurve(g_scene, RTC_GEOMETRY_TYPE_FLAT_LINEAR_CURVE, make_Vec4f(-4.5f, 0.0f, -2.f, 0.0f));
  addCurve(g_scene, RTC_GEOMETRY_TYPE_FLAT_CATMULL_ROM_CURVE, make_Vec4f(-1.5f, 0.0f, -2.f, 0.0f));
  addCurve(g_scene, RTC_GEOMETRY_TYPE_ROUND_CATMULL_ROM_CURVE, make_Vec4f(1.5f, 0.0f, -2.f, 0.0f));
  addCurve(g_scene, RTC_GEOMETRY_TYPE_NORMAL_ORIENTED_CATMULL_ROM_CURVE, make_Vec4f(+4.5f, 0.0f, -2.f, 0.0f));

  /* commit changes to scene */
  rtcCommitScene (g_scene);
}

/* task that renders a single screen tile */
Vec3f renderPixelStandard(float x, float y, const uniform ISPCCamera& camera, uniform RayStats& stats)
{
  uniform RTCIntersectContext context;
  rtcInitIntersectContext(&context);
  
  /* initialize ray */
  Ray ray = make_Ray(make_Vec3f(camera.xfm.p), make_Vec3f(normalize(x*camera.xfm.l.vx + y*camera.xfm.l.vy + camera.xfm.l.vz)), 0.0f, inf);

  /* intersect ray with scene */
  rtcIntersectV(g_scene,&context,RTCRayHit_(ray));
  RayStats_addRay(stats);

  /* shade pixels */
  Vec3f color = make_Vec3f(0.0f);
  if (ray.geomID != RTC_INVALID_GEOMETRY_ID)
  {
    /* interpolate diffuse color */
    Vec3f diffuse = make_Vec3f(1.0f,0.0f,0.0f);
    if (ray.geomID > 0)
    {
      foreach_unique (geomID in ray.geomID) {
        rtcInterpolateV0(rtcGetGeometry(g_scene,geomID),ray.primID,ray.u,ray.v,RTC_BUFFER_TYPE_VERTEX_ATTRIBUTE,0,&diffuse.x,3);
      }
      diffuse = 0.5f*diffuse;
    }

    /* calculate smooth shading normal */
    Vec3f Ng = normalize(ray.Ng);
    color = color + diffuse*0.5f;
    Vec3f lightDir = normalize(make_Vec3f(-1,-1,-1));

    /* initialize shadow ray */
    Ray shadow = make_Ray(ray.org + ray.tfar*ray.dir, neg(lightDir), 0.001f, inf, 0.0f);

    /* trace shadow ray */
    rtcOccludedV(g_scene,&context,RTCRay_(shadow));
    RayStats_addShadowRay(stats);

    /* add light contribution */
    if (shadow.tfar >= 0.0f) {
      Vec3f r = normalize(reflect(ray.dir,Ng));
      float s = pow(clamp(dot(r,lightDir),0.0f,1.0f),10.0f);
      float d = clamp(-dot(lightDir,Ng),0.0f,1.0f);
      color = color + diffuse*d + 0.5f*make_Vec3f(s);
    }
  }
  return color;
}

/* renders a single screen tile */
void renderTileStandard(uniform int taskIndex,
                        uniform int threadIndex,
                        uniform int* uniform pixels,
                        const uniform unsigned int width,
                        const uniform unsigned int height,
                        const uniform float time,
                        const uniform ISPCCamera& camera,
                        const uniform int numTilesX,
                        const uniform int numTilesY)
{
  const uniform unsigned int tileY = taskIndex / numTilesX;
  const uniform unsigned int tileX = taskIndex - tileY * numTilesX;
  const uniform unsigned int x0 = tileX * TILE_SIZE_X;
  const uniform unsigned int x1 = min(x0+TILE_SIZE_X,width);
  const uniform unsigned int y0 = tileY * TILE_SIZE_Y;
  const uniform unsigned int y1 = min(y0+TILE_SIZE_Y,height);

  foreach_tiled (y = y0 ... y1, x = x0 ... x1)
  {
    /* calculate pixel color */
    Vec3f color = renderPixelStandard((float)x,(float)y,camera,g_stats[threadIndex]);

    /* write color to framebuffer */
    unsigned int r = (unsigned int) (255.0f * clamp(color.x,0.0f,1.0f));
    unsigned int g = (unsigned int) (255.0f * clamp(color.y,0.0f,1.0f));
    unsigned int b = (unsigned int) (255.0f * clamp(color.z,0.0f,1.0f));
    pixels[y*width+x] = (b << 16) + (g << 8) + r;
  }
}

/* task that renders a single screen tile */
task void renderTileTask(uniform int* uniform pixels,
                         const uniform unsigned int width,
                         const uniform unsigned int height,
                         const uniform float time,
                         const uniform ISPCCamera& camera,
                         const uniform int numTilesX,
                         const uniform int numTilesY)
{
  renderTileStandard(taskIndex,threadIndex,pixels,width,height,time,camera,numTilesX,numTilesY);
}

export void renderFrameStandard (uniform int* uniform pixels,
                          const uniform unsigned int width,
                          const uniform unsigned int height,
                          const uniform float time,
                          const uniform ISPCCamera& camera)
{
  const uniform int numTilesX = (width +TILE_SIZE_X-1)/TILE_SIZE_X;
  const uniform int numTilesY = (height+TILE_SIZE_Y-1)/TILE_SIZE_Y;
  launch[numTilesX*numTilesY] renderTileTask(pixels,width,height,time,camera,numTilesX,numTilesY); sync;
}

/* called by the C++ code to render */
export void device_render (uniform int* uniform pixels,
                    const uniform unsigned int width,
                    const uniform unsigned int height,
                    const uniform float time,
                    const uniform ISPCCamera& camera)
{
}

/* called by the C++ code for cleanup */
export void device_cleanup ()
{
  rtcReleaseScene (g_scene); g_scene = NULL;
}
