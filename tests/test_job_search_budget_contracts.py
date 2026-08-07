from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DWARF = (ROOT / "df_mode" / "df_dwarf.gd").read_text(encoding="utf-8")


class JobSearchBudgetContracts(unittest.TestCase):
    def test_idle_workers_stagger_expensive_job_searches(self):
        tick = DWARF.split("func tick(world", 1)[1].split("\nfunc get_autonomous_status", 1)[0]
        self.assertIn("var job_search_due: bool = posmod(simulation_tick + id, 12) == 0", tick)
        self.assertGreaterEqual(tick.count("job_search_due and not jobs.is_empty()"), 2)

    def test_active_work_is_not_put_behind_search_budget(self):
        tick = DWARF.split("func tick(world", 1)[1].split("\nfunc get_autonomous_status", 1)[0]
        active = tick.split("# PRIORIDAD 4: Realizar trabajo activo asignado", 1)[1].split(
            "# PRIORIDAD 5: Buscar trabajo disponible", 1
        )[0]
        self.assertIn("_work_on_job(world)", active)
        self.assertLess(active.index("_work_on_job(world)"), active.index("job_search_due"))


if __name__ == "__main__":
    unittest.main()
