module HplProducts.TestTypes where
import FeatureModel.Types hiding (Success, Fail)
import Data.Generics
import BasicTypes
import HplAssets.UCM.Types
 
data SPLModel = SPLModel{featureModel :: FeatureModel,
                         splUcm :: UseCaseModel}
 
data InstanceModel = InstanceModel{featureConfiguration ::
                                   FeatureConfiguration,
                                   ucm :: UseCaseModel}
                   deriving (Data, Typeable)
 
data TransformationModel = UseCaseTransformation UseCaseTransformation
 
data ExportModel = ExportUcmXML
 
lstExport :: [ExportModel]
lstExport = [ExportUcmXML]
 
type ConfigurationKnowledge = [ConfigurationItem]
 
data ConfigurationItem = ConfigurationItem{expression ::
                                           FeatureExpression,
                                           transformations :: [TransformationModel]}
                       | ConstrainedConfigurationItem{expression :: FeatureExpression,
                                                      transformations :: [TransformationModel],
                                                      required :: FeatureExpression,
                                                      provided :: FeatureExpression}
 
constrained :: ConfigurationItem -> Bool
constrained (ConstrainedConfigurationItem _ _ _ _) = True
constrained _ = False
 
xml2Transformation ::
                     String -> [String] -> ParserResult TransformationModel
xml2Transformation "selectScenarios" ids
  = Success (UseCaseTransformation (SelectScenarios ids))
xml2Transformation "selectUseCases" ids
  = Success (UseCaseTransformation (SelectUseCases ids))
xml2Transformation "bindParameter" [x,y]
  = Success (UseCaseTransformation (BindParameter x y))
xml2Transformation "bindParameter" _
  = Fail
      "Invalid number of arguments to the transformation bindParameter"
xml2Transformation "evaluateAspects" ids
  = Success (UseCaseTransformation (EvaluateAspects ids))