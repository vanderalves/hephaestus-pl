--
-- Reusable driver code (build function) for the Hephaestus product line.
--
module HplAssets.Hephaestus.IO where

import HplProducts.Hephaestus
import HplProducts.HephaestusTypes
import HplAssets.Hephaestus.Types
import HplAssets.Hephaestus.MetaData
import FeatureModel.Types
import Language.Haskell.Syntax
import Language.Haskell.Parser
import Language.Haskell.Pretty
import Distribution.ModuleName

--
-- Invoke the build function for the Hephaestus product line.
-- A feature configuration is to be passed as argument.
-- Composition starts from the base product as asset base.
-- The resulting product (module) is stored in the file system.
--
buildHpl :: FeatureConfiguration -> IO ()
buildHpl fc
 = do
      x <- readFile "HplProducts/BaseProduct.hs"
      let (ParseOk y) = parseModule x
      x2 <- readFile "HplProducts/BaseProductTypes.hs"
      let (ParseOk y2) = parseModule x2
      let base = (SPLModel noFeatureModel (HephaestusModel [y, y2]))
      let (InstanceModel _ (HephaestusModel [p1, p2])) = build noFeatureModel fc ck base
      let (HsModule _ (Module m) _ _ _) = p1
      writeFile (toFilePath (fromString m) ++ ".hs") (prettyPrint p1)
      let (HsModule _ (Module m) _ _ _) = p2
      writeFile (toFilePath (fromString m) ++ ".hs") (prettyPrint p2)
  where
  ck = map (\(fe, ts) -> ConfigurationItem fe (map HephaestusTransformation ts)) configurationKnowledge