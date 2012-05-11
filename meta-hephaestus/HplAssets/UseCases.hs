module HplAssets.UseCases (
  transformUcm,
  emptyUcm
) where

import BasicTypes
import HplAssets.UCM.Types

import FeatureModel.Types
import Data.Generics -- função everywhere
-- *******************************************************
import HplProducts.TestTypes -- where is defined the data types SPLModel and InstanceModel
-- *******************************************************

emptyUcm :: UseCaseModel->UseCaseModel
emptyUcm ucmodel = ucmodel { useCases = [], aspects = [] }

emptyUseCase :: UseCase -> UseCase
emptyUseCase uc = uc { ucScenarios = [] }

splScenarios spl = ucmScenarios (splUcm spl)


transformUcm :: UseCaseTransformation -> SPLModel -> InstanceModel -> InstanceModel
transformUcm (SelectUseCases ids) spl product = 
  addScenariosToInstance (scs, spl, product) 
  where scs = concat $ map ucScenarios [uc | uc <- useCases (splUcm spl), ucId uc `elem` ids]
transformUcm (SelectScenarios ids) spl product = 
  addScenariosToInstance (scs, spl, product) 
  where scs = [s | s <- splScenarios spl, scId s `elem` ids]
transformUcm (BindParameter pid fid) spl product = 
  bindParameter steps (parenthesize options) pid product 
  where 
    steps = [s | s <- ucmSteps (ucm product), s `refers` pid] 
    options = concat (map featureOptionsValues [f | f <- flatten (fcTree (featureConfiguration product)), fId (fnode f) == fid]) 
    bindParameter [] o pid p = p 
    bindParameter (s:ss) o pid p = bindParameter ss o pid (gReplaceParameterInScenario (sId s) pid o p) 
transformUcm (EvaluateAspects ids) spl product = 
  evaluateListOfAdvice as product 
  where as = concat [advices a | a <- aspects (splUcm spl), (aspectId a) `elem` ids]


-- this is a map function that adds a list of scenarios 
-- to a use case model.
addScenariosToInstance :: ([Scenario], SPLModel, InstanceModel) -> InstanceModel
addScenariosToInstance ([], spl, product) = product
addScenariosToInstance ((s:ss), spl, product) = addScenariosToInstance (ss, spl, product') 
 where 
  product' = addScenarioToInstance (s, sUseCase, product) 
  sUseCase = findUseCaseFromScenario (useCases (splUcm spl)) s

-- add a single scenario to a use case model.
addScenarioToInstance :: (Scenario, Maybe UseCase, InstanceModel) -> InstanceModel
addScenarioToInstance (s, Nothing, product) =  error "Scenario not declared within a use case"
addScenarioToInstance (s, (Just sUseCase), product)  = 
 let
  pUseCase = [u | u <- useCases (ucm product), (ucId sUseCase) == (ucId u)]
  eUseCase = (emptyUseCase sUseCase) { ucScenarios = [s] } 
 in case pUseCase of
     []  -> gAddUseCase eUseCase product
     [u] -> gAddScenario (ucId u) s product

-- this is the generic function for adding a scenario.
-- it follows the SYB pattern. 
gAddScenario :: Id -> Scenario -> InstanceModel -> InstanceModel
gAddScenario i s = everywhere (mkT (addOrReplaceScenario i s))

-- this is the generic function for adding a use case. 
-- it follows the SYB pattern. 
gAddUseCase :: UseCase -> InstanceModel -> InstanceModel 
gAddUseCase u = everywhere (mkT (addOrReplaceUseCase u))
      
-- add or replace a scenarion to a use case. this is 
-- an auxiliarly function to the 'selectScenario' transformation.
addOrReplaceScenario :: Id -> Scenario -> UseCase -> UseCase
addOrReplaceScenario i sc uc =
 if (ucId uc == i) 
  then 
   let scs = ucScenarios uc 
   in uc { ucScenarios = [s | s <- scs, s /= sc] ++ [sc]}
  else uc 

-- add or replace a use case to a use case model. this is 
-- an auxiliarly function to the 'selectScenario' transformation.
addOrReplaceUseCase :: UseCase -> UseCaseModel -> UseCaseModel
addOrReplaceUseCase uc ucModel = 
 let ucs = useCases ucModel 
 in ucModel { useCases = [u | u <- ucs, u /= uc ] ++ [uc]}    


-- evaluate a list of advices
evaluateListOfAdvice :: [Advice] -> InstanceModel -> InstanceModel
evaluateListOfAdvice [] p = p
evaluateListOfAdvice (x:xs) p = evaluateListOfAdvice xs (genEvaluateAdvice x p)

-- this is the generic function for evaluating 
-- an advice. It follows the Scrap Your Boilerplate (SYB)
-- pattern. 
genEvaluateAdvice :: Advice -> InstanceModel -> InstanceModel  
genEvaluateAdvice a = everywhere (mkT (evaluateAdvice a))

evaluateAdvice :: Advice -> Scenario -> Scenario
evaluateAdvice a s = foldl (compose a) s pcs 
 where pcs = pointCut a

compose :: Advice -> Scenario  -> StepRef -> Scenario
compose adv sc pc = 
 if (matches pc sc) 
  then sc { steps = (compose' (advType adv)) aFlow sFlow }
  else sc
 where 
  compose' (Before) = concatBefore (match pc)
  compose' (After)  = concatAfter  (match pc)
  compose' (Around) = concatAround (match pc) proceed
  aFlow = aspectualFlow adv
  sFlow = steps sc

-- just an auxiliarly function for checking if a 
-- step refers to a parameter. this function might 
-- be parameterized with different delimiters.   
refers :: Step -> Id -> Bool
refers s pid = 
 let 
  w = "{" ++ pid ++ "}" 
  wExists = existsWord w
 in (wExists (action s)) || (wExists (state s)) || (wExists (response s))
 
replaceParameterInScenario :: Id -> String -> String -> Scenario -> Scenario
replaceParameterInScenario sid fp ap scn = 
 let sts = steps scn 
 in scn { steps = map (replaceStringInStep sid fp ap) sts }

-- just an auxiliarly function for replacin a string in a step. 
-- actually, it replaces a string at any place of a step: action, 
-- condition, or response. 
replaceStringInStep :: Id -> String -> String -> Step -> Step
replaceStringInStep sid old new step = 
 if (sId step /= sid) 
  then step
  else step { action = rfn a, state = rfn s, response = rfn r }  
   where 
    a = action step
    s = state step
    r = response step  
    rfn = replaceString ("{"++old++"}") new
 
-- this is the generic function for replacing a string into a step (identified 
-- by 'sid'). It follows the SYB pattern. 
gReplaceParameterInScenario :: Id -> String -> String -> InstanceModel -> InstanceModel
gReplaceParameterInScenario sid fp ap = everywhere (mkT (replaceParameterInScenario sid fp ap)) 
      










