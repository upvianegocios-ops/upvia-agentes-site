import { describe, expect, it, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { OptionButton } from '@/components/ui/OptionButton';

describe('OptionButton', () => {
  it('chama onClick ao ser pressionado', () => {
    const onClick = vi.fn();
    render(<OptionButton label="A" onClick={onClick} />);
    fireEvent.click(screen.getByText('A'));
    expect(onClick).toHaveBeenCalledOnce();
  });

  it('nunca comunica certo/errado só por cor: sempre inclui ícone/texto (seção 6)', () => {
    render(<OptionButton label="A" onClick={() => {}} status="correct" />);
    expect(screen.getByText('✅')).toBeInTheDocument();
  });

  it('fica desabilitado quando disabled=true', () => {
    render(<OptionButton label="A" onClick={() => {}} disabled />);
    expect(screen.getByText('A').closest('button')).toBeDisabled();
  });
});
