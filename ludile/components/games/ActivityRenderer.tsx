import type { GameProps } from '@/lib/game-engine/game-props';
import { CacaLetra } from './CacaLetra';
import { Memoria } from './Memoria';
import { QualEOSom } from './QualEOSom';

// Motor genérico de atividades (seção 23): despacha pelo activity_type, sem
// nenhum jogo hardcoded fora deste ponto único de roteamento.
export function ActivityRenderer(props: GameProps) {
  switch (props.activity.activityType) {
    case 'caca_letra':
      return <CacaLetra {...props} />;
    case 'memoria':
      return <Memoria {...props} />;
    case 'qual_e_o_som':
      return <QualEOSom {...props} />;
    default:
      return (
        <p className="text-center text-child-base text-slate-500">
          Este tipo de atividade ({props.activity.activityType}) ainda não está disponível nesta
          versão do MVP.
        </p>
      );
  }
}
