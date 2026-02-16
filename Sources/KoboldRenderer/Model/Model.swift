struct KModel {
    let name: String
    let meshes: [MultiBufferMesh]
    let textures: [String: TextureData]
    let boundingBox: KBoundingBox
}
