
import Foundation

// MARK: - SourcePipelineInfo
struct SourcePipelineInfo :Codable{
   let result: SourcePipelineInfoResult
   init(){
       result = SourcePipelineInfoResult()
   }
}

// MARK: - SourcePipelineInfoResult
struct SourcePipelineInfoResult :Codable{
   let projectList: [SourcePipelineInfoProjectList]
    init(){
        projectList = []
    }
}

// MARK: - SourcePipelineInfoProjectList
struct SourcePipelineInfoProjectList :Codable,Hashable{
   let id: Int
   let name: String
    init(){
        id = 0
        name = ""
    }
    init(_ id:Int,_ name:String){
        self.id = id
        self.name = name
    }
}
