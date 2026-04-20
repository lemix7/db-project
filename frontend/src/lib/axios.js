import {
  MOCK_USERS, MOCK_FILMS, MOCK_CREW, MOCK_DEPARTMENTS,
  MOCK_EXPENSES, MOCK_BUDGETS, MOCK_FILM_CREW,
  MOCK_STATS, MOCK_QUERY_RESULTS,
} from './mockData'

// ─── In-memory state ──────────────────────────────────────────────────────────
let films    = [...MOCK_FILMS]
let crew     = [...MOCK_CREW]
let expenses = [...MOCK_EXPENSES]
let users    = [...MOCK_USERS]
let filmCrew = [...MOCK_FILM_CREW]
let nextIds  = { film: 6, crew: 7, expense: 11, user: 9, assignment: 9 }

const delay = (ms = 150) => new Promise(r => setTimeout(r, ms))

// ─── Mock handler ─────────────────────────────────────────────────────────────
async function mockRequest(method, url, data = {}) {
  await delay()
  method = method.toLowerCase()

  // AUTH
  if (url === '/api/auth/login/' && method === 'post') {
    const u = users.find(u => u.username === data.username && u.password === data.password)
    if (!u) {
      const err = new Error('Invalid credentials.')
      err.response = { status: 401, data: { detail: 'Invalid username or password.' } }
      throw err
    }
    const payload = { user_id: u.user_id, username: u.username, role: u.role, full_name: u.full_name, exp: Math.floor(Date.now() / 1000) + 86400 }
    const fakeToken = 'fake.' + btoa(JSON.stringify(payload)) + '.sig'
    return { access: fakeToken, refresh: 'refresh_token' }
  }

  if (url === '/api/auth/register/' && method === 'post') {
    const exists = users.find(u => u.username === data.username || u.email === data.email)
    if (exists) {
      const err = new Error('User exists.')
      err.response = { status: 400, data: { username: ['A user with that username already exists.'] } }
      throw err
    }
    const newUser = { ...data, user_id: nextIds.user++, is_active: true }
    users.push(newUser)
    return newUser
  }

  // FILMS
  if (url === '/api/films/' && method === 'get') return films
  if (url === '/api/films/' && method === 'post') {
    const newFilm = { ...data, film_id: nextIds.film++, created_by_name: 'You' }
    films.push(newFilm)
    return newFilm
  }
  const filmMatch = url.match(/^\/api\/films\/(\d+)\/$/)
  if (filmMatch) {
    const id = parseInt(filmMatch[1])
    if (method === 'get') {
      const film = films.find(f => f.film_id === id)
      if (!film) { const e = new Error(); e.response = { status: 404 }; throw e }
      return film
    }
    if (method === 'put') { films = films.map(f => f.film_id === id ? { ...f, ...data } : f); return films.find(f => f.film_id === id) }
    if (method === 'delete') { films = films.filter(f => f.film_id !== id); return {} }
  }
  if (url.match(/^\/api\/films\/(\d+)\/crew\/$/) && method === 'get') {
    const id = parseInt(url.match(/(\d+)/)[1])
    return filmCrew.filter(fc => fc.film_id === id)
  }
  if (url.match(/^\/api\/films\/(\d+)\/budget\/$/) && method === 'get') {
    const id = parseInt(url.match(/(\d+)/)[1])
    return MOCK_BUDGETS.find(b => b.film_id === id) || null
  }

  // CREW
  if (url === '/api/crew/' && method === 'get') return crew
  if (url === '/api/crew/' && method === 'post') {
    const dept = MOCK_DEPARTMENTS.find(d => d.department_id === parseInt(data.department_id))
    const newMember = { ...data, crew_id: nextIds.crew++, full_name: data.full_name || 'New Member', department_name: dept?.name || '' }
    crew.push(newMember)
    return newMember
  }
  const crewMatch = url.match(/^\/api\/crew\/(\d+)\/$/)
  if (crewMatch) {
    const id = parseInt(crewMatch[1])
    if (method === 'put') {
      const dept = MOCK_DEPARTMENTS.find(d => d.department_id === parseInt(data.department_id))
      crew = crew.map(c => c.crew_id === id ? { ...c, ...data, department_name: dept?.name || c.department_name } : c)
      return crew.find(c => c.crew_id === id)
    }
    if (method === 'delete') { crew = crew.filter(c => c.crew_id !== id); return {} }
  }

  // FILM CREW ASSIGNMENT
  if (url === '/api/film-crew/' && method === 'post') {
    const filmId = parseInt(data.film_id)
    const crewId = parseInt(data.crew_id)
    if (filmCrew.find(fc => fc.film_id === filmId && fc.crew_id === crewId)) {
      const e = new Error(); e.response = { status: 400, data: { detail: 'Crew member already assigned to this film.' } }; throw e
    }
    const member = crew.find(c => c.crew_id === crewId)
    const assignment = { assignment_id: nextIds.assignment++, film_id: filmId, crew_id: crewId, crew_member_name: member?.full_name || '', job_title: member?.job_title || '', department_name: member?.department_name || '', role_on_film: data.role_on_film || '' }
    filmCrew.push(assignment)
    return assignment
  }

  // DEPARTMENTS
  if (url === '/api/departments/' && method === 'get') return MOCK_DEPARTMENTS

  // EXPENSES
  if (url === '/api/expenses/' && method === 'get') return expenses
  if (url === '/api/expenses/' && method === 'post') {
    const film = films.find(f => f.film_id === parseInt(data.film_id))
    const newExpense = { ...data, expense_id: nextIds.expense++, film_id: parseInt(data.film_id), amount: parseFloat(data.amount), film_title: film?.title || '', recorded_by_name: 'You' }
    expenses.push(newExpense)
    return newExpense
  }
  const expMatch = url.match(/^\/api\/expenses\/(\d+)\/$/)
  if (expMatch) {
    const id = parseInt(expMatch[1])
    if (method === 'put') {
      const film = films.find(f => f.film_id === parseInt(data.film_id))
      expenses = expenses.map(e => e.expense_id === id ? { ...e, ...data, film_title: film?.title || e.film_title } : e)
      return expenses.find(e => e.expense_id === id)
    }
    if (method === 'delete') { expenses = expenses.filter(e => e.expense_id !== id); return {} }
  }

  // USERS
  if (url === '/api/users/' && method === 'get') return users
  if (url === '/api/users/' && method === 'post') {
    const newUser = { ...data, user_id: nextIds.user++, is_active: true }
    users.push(newUser)
    return newUser
  }
  const userMatch = url.match(/^\/api\/users\/(\d+)\/$/)
  if (userMatch) {
    const id = parseInt(userMatch[1])
    if (method === 'put' || method === 'patch') { users = users.map(u => u.user_id === id ? { ...u, ...data } : u); return users.find(u => u.user_id === id) }
    if (method === 'delete') { users = users.filter(u => u.user_id !== id); return {} }
  }

  // STATS
  if (url === '/api/stats/summary/' && method === 'get') return MOCK_STATS
  if (url === '/api/stats/queries/'  && method === 'get') return MOCK_QUERY_RESULTS

  const e = new Error(`No mock handler: ${method.toUpperCase()} ${url}`)
  e.response = { status: 404, data: { detail: e.message } }
  throw e
}

// ─── Drop-in replacement for axios with the same interface ────────────────────
function makeRequest(method) {
  return async (url, dataOrConfig, config) => {
    const data = method === 'get' || method === 'delete' ? undefined : dataOrConfig
    try {
      const result = await mockRequest(method, url, data)
      return { data: result }
    } catch (err) {
      // Already has .response attached — rethrow as-is
      throw err
    }
  }
}

const api = {
  get:    makeRequest('get'),
  post:   makeRequest('post'),
  put:    makeRequest('put'),
  patch:  makeRequest('patch'),
  delete: makeRequest('delete'),
}

export default api
