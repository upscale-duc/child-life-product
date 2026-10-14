import { scenes, type Scene } from '../components/scenes';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { Keepsakes } from './Keepsakes';

const photos: Scene[] = ['firstBirthday', 'firstSchoolDay', 'dreams'];

/** Lớn lên cùng con (28-landing-v5b-home §5): dark band with three stepped photos (1, 6 and 12
 *  years old), then "Kỷ niệm của con". */
export function GrowUp() {
  const { c } = useSite();
  const g = c.home.growUp;
  return (
    <section id="lon-len" className="grow-up" aria-labelledby="grow-up-title">
      <div className="grow-up__band reveal">
        <div className="grow-up__copy">
          <p className="eyebrow eyebrow--on-dark hide-mobile">{g.eyebrow}</p>
          <h2 id="grow-up-title" className="grow-up__title">
            {g.title}
          </h2>
          <p className="grow-up__body">
            <span className="only-desktop-inline">{g.body}</span>
            <span className="only-mobile-inline">{g.bodyShort}</span>
          </p>
        </div>
        <ul className="grow-up__years">
          {g.years.map((year, i) => (
            <li key={year.year} className="pop" style={staggerStyle(i)}>
              <img
                className={`grow-up__photo grow-up__photo--${i + 1}`}
                src={scenes[photos[i]!]}
                alt=""
                loading="lazy"
                decoding="async"
              />
              <strong>{year.year}</strong>
              <span className="only-desktop-inline">{year.caption}</span>
            </li>
          ))}
        </ul>
      </div>
      <Keepsakes />
    </section>
  );
}
