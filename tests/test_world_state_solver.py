import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools/world'))
from state_proof import prove
from gate_conditions import combine
class PhysicalStateProofTests(unittest.TestCase):
 def test_one_way_fall_is_a_trap(self):
  self.assertIsNotNone(prove(2,0,{(0,1):{0}},2,2)['failure'])
 def test_entry_key_does_not_grant_another_exit_key(self):
  self.assertIsNotNone(prove(2,0,{(0,1):{1},(1,0):{2}},2,2)['failure'])
 def test_movement_entry_superset_catches_hidden_trap(self):
  self.assertIsNotNone(prove(2,0,{},2,2,[{0},{0}])['failure'])
 def test_crawl_tunnel_is_reversible_only_with_crawl(self):
  r=prove(2,0,{(0,1):{2},(1,0):{2}},2,3)
  self.assertIsNone(r['failure']);self.assertEqual(r['states_checked'],32)
 def test_saved_reveal_is_alternative_to_attempt_vision(self):
  self.assertEqual(combine(3,[{1,4},{2}]),frozenset([3,6]))
  r=prove(2,0,{(0,1):{1,4},(1,0):{1,4}},2,2,symbolic_only=True)
  self.assertIsNone(r['failure']);self.assertEqual(r['states_covered'],16)
 def test_symbolic_history_catches_asymmetric_exit(self):
  self.assertIsNotNone(prove(2,0,{(0,1):{1,4},(1,0):{1}},2,2,symbolic_only=True)['failure'])
if __name__=='__main__':unittest.main()
